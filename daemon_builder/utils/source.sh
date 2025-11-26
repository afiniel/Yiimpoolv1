#!/bin/env bash

# This is the source file that compiles coin daemon.
#
# Author: Afiniel
#
# It uses:
#  Berkeley 4.8 with autogen.sh file.
#  Berkeley 5.1 with autogen.sh file.
#  Berkeley 5.3 with autogen.sh file.
#  Berkeley 6.2 with autogen.sh file.
#  makefile.unix file.
#  CMake file.
#  UTIL folder contains BUILD.sh file.
#  precompiled coin. NEED TO BE LINUX Version!
#
# Updated: 2024-03-20

source /etc/daemonbuilder.sh
source /etc/functions.sh
source $STORAGE_ROOT/daemon_builder/.daemon_builder.my.cnf
source $STORAGE_ROOT/daemon_builder/conf/info.sh

YIIMPOLL=/etc/yiimpool.conf
if [[ -f "$YIIMPOLL" ]]; then
    source /etc/yiimpool.conf
    YIIMPCONF=true
fi

CREATECOIN=true
now=$(date +"%m_%d_%Y")
MIN_CPUS_FOR_COMPILATION=3

if ! NPROC=$(nproc); then
    print_error "nproc command not found. Failed to run."
    exit 1
fi

if [[ "$NPROC" -le "$MIN_CPUS_FOR_COMPILATION" ]]; then
    NPROC=1
else
    NPROC=$((NPROC - 2))
fi

print_header "Setting Up Build Environment"
print_status "Creating temporary build directory..."

source $STORAGE_ROOT/daemon_builder/.daemon_builder.my.cnf

if [[ ! -e "$STORAGE_ROOT/daemon_builder/temp_coin_builds" ]]; then
    sudo mkdir -p $STORAGE_ROOT/daemon_builder/temp_coin_builds
    print_success "Created temp_coin_builds directory"
else
    sudo rm -rf $STORAGE_ROOT/daemon_builder/temp_coin_builds/*
    print_info "Cleaned existing temp_coin_builds directory"
fi

sudo setfacl -m u:${USERSERVER}:rwx $STORAGE_ROOT/daemon_builder/temp_coin_builds
cd $STORAGE_ROOT/daemon_builder/temp_coin_builds

print_header "Coin Configuration"

input_box "Coin Information" \
"Please enter the Coin Symbol. Example: BTC
\n\n*To paste, use Ctrl+Shift+V (or right-click in some terminals).
\n\nCoin Name:" \
"" \
coin

convertlistalgos=$(find ${PATH_STRATUM}/config/ -mindepth 1 -maxdepth 1 -type f -not -name '.*' -not -name '*.sh' -not -name '*.log' -not -name 'stratum.*' -not -name '*.*.*' -iname '*.conf' -execdir basename -s '.conf' {} +);
optionslistalgos=$(echo -e "${convertlistalgos}" | awk '{ printf "%s on\n", $1}' | sort | uniq | grep [[:alnum:]])

DIALOGFORLISTALGOS=${DIALOGFORLISTALGOS=dialog}
tempfile=$(tempfile 2>/dev/null) || tempfile=/tmp/test$$
trap "rm -f $tempfile" 0 1 2 5 15

$DIALOGFORLISTALGOS --colors --title "\Zb\Zr\Z7| Select Algorithm: ${coin^^} |" --clear --colors --no-items --nocancel --shadow \
--radiolist "\n\
    Select the mining algorithm for your coin.\n\
    Use UP/DOWN arrows or number keys 1-9 to navigate.\n\
    Press SPACE to select an option.\n\n\
Choose from available algorithms:" \
55 60 47 $optionslistalgos 2> $tempfile

retvalalgoselected=$?
ALGOSELECTED=$(cat $tempfile)
case $retvalalgoselected in
    0)
        coinalgo="${ALGOSELECTED}"
        print_success "Selected algorithm: ${ALGOSELECTED}"
        ;;
    1)
        print_error "Installation cancelled by user"
        print_info "Use daemonbuilder to start a new installation"
        exit
        ;;
    255)
        print_error "Installation cancelled (ESC pressed)"
        print_info "Use daemonbuilder to start a new installation"
        exit
        ;;
esac

print_divider

print_header "Coin Binary Installation"

if [[ ("$precompiled" == "true") ]]; then
    print_status "Preparing to install precompiled binary..."
    
    input_box "Precompiled Binary Information" \
    "Please enter the URL link to the precompiled compressed file. 
    \n\nExample: bitcoin-0.16.3-x86_64-linux-gnu.tar.gz
    \n\nSupported formats: .tar.gz, .zip, .7z
    \n\n*To paste, use Ctrl+Shift+V (or right-click in some terminals).
    \n\nPrecompiled Binary URL:" \
    "" \
    coin_precompiled
else
    print_header "Source Code"
    
    input_box "GitHub Repository" \
    "Please enter the GitHub repository link.
    \n\nExample: https://github.com/example-repo-name/coin-wallet.git
    \n\n*To paste, use Ctrl+Shift+V (or right-click in some terminals).
    \n\nGitHub Repository Link:" \
    "" \
    git_hub
    
    dialog --title "Development Branch Selection" \
    --yesno "Would you like to use the development branch instead of main?\n\nSelect Yes to use the development branch." 8 60
    response=$?
    case $response in
        0) 
            swithdevelop=yes
            print_info "Using development branch"
            ;;
        1) 
            swithdevelop=no
            print_info "Using main branch"
            ;;
        255) 
            print_warning "ESC key pressed - defaulting to main branch"
            swithdevelop=no
            ;;
    esac
    
    if [[ ("${swithdevelop}" == "no") ]]; then
        dialog --title "Branch Selection" \
        --yesno "Would you like to use a specific branch?\n\nSelect Yes to specify a particular version." 8 60
        response=$?
        case $response in
            0) 
                branch_git_hub=yes
                print_info "Will prompt for specific branch"
                ;;
            1) 
                branch_git_hub=no
                print_info "Using default branch"
                ;;
            255) 
                print_warning "ESC key pressed - using default branch"
                branch_git_hub=no
                ;;
        esac
        
        if [[ ("${branch_git_hub}" == "yes") ]]; then
            input_box "Git Branch Selection" \
            "Please enter the branch name to use.
            \n\nExample: v1.2.3 or feature/new-update
            \n\n*To paste, use Ctrl+Shift+V (or right-click in some terminals).
            \n\nBranch name:" \
            "" \
            branch_git_hub_ver
            
            print_info "Selected branch: ${branch_git_hub_ver}"
        fi
    fi
fi
clear
print_divider

set -e
print_header "Starting Installation: ${coin^^}"

coindir=$coin$now

echo '
lastcoin='"${coindir}"'
' | sudo -E tee $STORAGE_ROOT/daemon_builder/temp_coin_builds/.lastcoin.conf >/dev/null 2>&1

if [[ ! -e $coindir ]]; then
    if [[ ("$precompiled" == "true") ]]; then
        print_status "Downloading precompiled binary..."
        mkdir $coindir
        cd "${coindir}"
        sudo wget $coin_precompiled
        print_success "Downloaded precompiled binary"
    else
        print_status "Cloning repository..."
        git clone $git_hub $coindir
        cd "${coindir}"
        print_success "Repository cloned successfully"
        
        if [[ ("${branch_git_hub}" == "yes") ]]; then
            print_status "Checking out branch: ${branch_git_hub_ver}..."
            git fetch
            git checkout "$branch_git_hub_ver"
            print_success "Switched to branch: ${branch_git_hub_ver}"
        fi
        
        if [[ ("${swithdevelop}" == "yes") ]]; then
            print_status "Switching to development branch..."
            git checkout develop
            print_success "Switched to development branch"
        fi
    fi
    errorexist="false"
else
    print_error "${coindir} already exists in temp folder"
    print_info "If there was an error in the build use the build error options on the installer"
    errorexist="true"
    exit 0
fi

if [[ ("${errorexist}" == "false") ]]; then
    print_status "Setting permissions for build directory..."
    sudo chmod -R 777 $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}
    sudo find $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/ -type d -exec chmod 777 {} \;
    sudo find $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/ -type f -exec chmod 777 {} \;
    print_success "Permissions set successfully"
fi

if [[ ("$autogen" == "true") ]]; then
    if [[ ("$berkeley" == "4.8") ]]; then
        print_header "Building ${coin^^} with Berkeley DB 4.8"
        
        basedir=$(pwd)
        
        FILEAUTOGEN=$STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/autogen.sh
        if [[ ! -f "$FILEAUTOGEN" ]]; then
            print_warning "autogen.sh not found in root directory"
            print_info "Available directories:"
            echo -e "${YELLOW}"
            find . -maxdepth 1 -type d \( -perm -1 -o \( -perm -10 -o -perm -100 \) \) -printf "%f\n"
            echo -e "${NC}"
            
            read -r -e -p "Enter the installation folder name (e.g. bitcoin): " repotherinstall
            
            print_status "Moving files to build directory..."
            sudo mv $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/${repotherinstall}/* $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}
            print_success "Files moved successfully"
        fi
        
        print_status "Running autogen.sh..."
        sh autogen.sh
        print_success "autogen.sh completed"
        
        if [[ ! -e "$STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/share/genbuild.sh" ]]; then
            print_info "genbuild.sh not found - skipping"
        else
            sudo chmod 777 $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/share/genbuild.sh
        fi
        
        if [[ ! -e "$STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/src/leveldb/build_detect_platform" ]]; then
            print_info "build_detect_platform not found - skipping"
        else
            sudo chmod 777 $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/src/leveldb/build_detect_platform
        fi
        
        print_status "Configuring build..."
        sudo find $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/ -type d -exec chmod 777 {} \;
        sudo find $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/ -type f -exec chmod 777 {} \;
        
        ./configure CPPFLAGS="-I$STORAGE_ROOT/daemon_builder/berkeley/db4/include -O2" LDFLAGS="-L$STORAGE_ROOT/daemon_builder/berkeley/db4/lib" --with-incompatible-bdb --without-gui --disable-tests
        print_success "Configuration completed"
        
        print_status "Building ${coin^^}..."
        sudo find $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/ -type d -exec chmod 777 {} \;
        sudo find $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/ -type f -exec chmod 777 {} \;
        
        TMP=$(tempfile)
        print_status "Running make with ${NPROC} cores..."
        make -j${NPROC} 2>&1 | tee $TMP
        
        if [ ${PIPESTATUS[0]} -eq 0 ]; then
            print_success "Build completed successfully"
        else
            print_error "Build failed - check the error log"
            cat $TMP
            rm $TMP
            exit 1
        fi
        rm $TMP
    fi
    
    # Build the coin under berkeley 5.1
    if [[ ("$berkeley" == "5.1") ]]; then
        print_header "Building ${coin^^} with Berkeley DB 5.1"
        
        basedir=$(pwd)
        
        FILEAUTOGEN=$STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/autogen.sh
        if [[ ! -f "$FILEAUTOGEN" ]]; then
            print_warning "autogen.sh not found in root directory"
            print_info "Available directories:"
            echo -e "${YELLOW}"
            find . -maxdepth 1 -type d \( -perm -1 -o \( -perm -10 -o -perm -100 \) \) -printf "%f\n"
            echo -e "${NC}"
            
            read -r -e -p "Enter the installation folder name (e.g. bitcoin): " repotherinstall
            
            print_status "Moving files to build directory..."
            sudo mv $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/${repotherinstall}/* $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}
            print_success "Files moved successfully"
        fi
        
        print_status "Running autogen.sh..."
        sh autogen.sh
        print_success "autogen.sh completed"
        
        if [[ ! -e "$STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/share/genbuild.sh" ]]; then
            print_info "genbuild.sh not found - skipping"
        else
            sudo chmod 777 $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/share/genbuild.sh
        fi
        
        if [[ ! -e "$STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/src/leveldb/build_detect_platform" ]]; then
            print_info "build_detect_platform not found - skipping"
        else
            sudo chmod 777 $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/src/leveldb/build_detect_platform
        fi
        
        print_status "Configuring build..."
        sudo find $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/ -type d -exec chmod 777 {} \;
        sudo find $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/ -type f -exec chmod 777 {} \;
        
        ./configure CPPFLAGS="-I$STORAGE_ROOT/daemon_builder/berkeley/db5/include -O2" LDFLAGS="-L$STORAGE_ROOT/daemon_builder/berkeley/db5/lib" --with-incompatible-bdb --without-gui --disable-tests
        print_success "Configuration completed"
        
        print_status "Building ${coin^^}..."
        sudo find $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/ -type d -exec chmod 777 {} \;
        sudo find $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/ -type f -exec chmod 777 {} \;
        
        TMP=$(tempfile)
        print_status "Running make with ${NPROC} cores..."
        make -j${NPROC} 2>&1 | tee $TMP
        
        if [ ${PIPESTATUS[0]} -eq 0 ]; then
            print_success "Build completed successfully"
        else
            print_error "Build failed - check the error log"
            cat $TMP
            rm $TMP
            exit 1
        fi
        rm $TMP
    fi
    
    # Build the coin under berkeley 5.3
    if [[ ("$berkeley" == "5.3") ]]; then
        echo
		
        echo -e "$CYAN ------------------------------------------------------------------------------- 	$NC"
        echo -e "$GREEN   Starting Building coin $MAGENTA ${coin^^} $NC using Berkeley 5.3	$NC"
        echo -e "$CYAN ------------------------------------------------------------------------------- 	$NC"
        echo
        basedir=$(pwd)
        
        FILEAUTOGEN=$STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/autogen.sh
        if [[ ! -f "$FILEAUTOGEN" ]]; then
            echo -e "$YELLOW"
            find . -maxdepth 1 -type d \( -perm -1 -o \( -perm -10 -o -perm -100 \) \) -printf "%f\n"
            echo -e "$NC$MAGENTA"
            read -r -e -p "Where is the folder that contains the installation ${coin^^}, example bitcoin :" repotherinstall
            echo -e "$NC"
			clear;
            echo -e "$CYAN ------------------------------------------------------------------------------- 	$NC"
            echo -e "$GREEN   Moving files and Starting Building coin $MAGENTA ${coin^^} 					$NC"
            echo -e "$CYAN ------------------------------------------------------------------------------- 	$NC"
            echo
            
            sudo mv $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/${repotherinstall}/* $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}
            
        fi
        
        sh autogen.sh
        
        if [[ ! -e "$STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/share/genbuild.sh" ]]; then
            echo "genbuild.sh not found skipping"
        else
            sudo chmod 777 $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/share/genbuild.sh
        fi
        
        if [[ ! -e "$STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/src/leveldb/build_detect_platform" ]]; then
            echo "build_detect_platform not found skipping"
        else
            sudo chmod 777 $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/src/leveldb/build_detect_platform
        fi
        echo
		clear;
        echo -e "$CYAN ------------------------------------------------------------------------------- 	$NC"
        echo -e "$GREEN   Starting configure coin...													$NC"
        echo -e "$CYAN ------------------------------------------------------------------------------- 	$NC"
        echo
        sudo find $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/ -type d -exec chmod 777 {} \;
        sudo find $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/ -type f -exec chmod 777 {} \;
        
        ./configure CPPFLAGS="-I$STORAGE_ROOT/daemon_builder/berkeley/db5.3/include -O2" LDFLAGS="-L$STORAGE_ROOT/daemon_builder/berkeley/db5.3/lib" --with-incompatible-bdb --without-gui --disable-tests
        echo
		clear;
        echo -e "$CYAN ------------------------------------------------------------------------------- 	$NC"
        echo -e "$GREEN   Starting make coin...															$NC"
        echo -e "$CYAN ------------------------------------------------------------------------------- 	$NC"
        echo
        sudo find $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/ -type d -exec chmod 777 {} \;
        sudo find $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/ -type f -exec chmod 777 {} \;
        
        # make install
        TMP=$(tempfile)
        make -j${NPROC} 2>&1 | tee $TMP
        OUTPUT=$(cat $TMP)
        echo $OUTPUT
        rm $TMP
    fi
    
    # Build the coin under berkeley 6.2
    if [[ ("$berkeley" == "6.2") ]]; then
        echo
		clear;
        echo -e "$CYAN ------------------------------------------------------------------------------- 	$NC"
        echo -e "$GREEN   Starting Building coin $MAGENTA ${coin^^} $NC using Berkeley 6.2	$NC"
        echo -e "$CYAN ------------------------------------------------------------------------------- 	$NC"
        echo
        basedir=$(pwd)
        
        FILEAUTOGEN=$STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/autogen.sh
        if [[ ! -f "$FILEAUTOGEN" ]]; then
            echo -e "$YELLOW"
            find . -maxdepth 1 -type d \( -perm -1 -o \( -perm -10 -o -perm -100 \) \) -printf "%f\n"
            echo -e "$NC$MAGENTA"
            read -r -e -p "Where is the folder that contains the installation ${coin^^}, example bitcoin :" repotherinstall
            echo -e "$NC"
			clear;
            echo -e "$CYAN ------------------------------------------------------------------------------- 	$NC"
            echo -e "$GREEN   Moving files and Starting Building coin $MAGENTA ${coin^^} 					$NC"
            echo -e "$CYAN ------------------------------------------------------------------------------- 	$NC"
            echo
            
            sudo mv $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/${repotherinstall}/* $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}
            
        fi
        
        sh autogen.sh
        
        if [[ ! -e "$STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/share/genbuild.sh" ]]; then
            echo "genbuild.sh not found skipping"
        else
            sudo chmod 777 $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/share/genbuild.sh
        fi
        
        if [[ ! -e "$STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/src/leveldb/build_detect_platform" ]]; then
            echo "build_detect_platform not found skipping"
        else
            sudo chmod 777 $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/src/leveldb/build_detect_platform
        fi
        echo
		clear;
        echo -e "$CYAN ------------------------------------------------------------------------------- 	$NC"
        echo -e "$GREEN   Starting configure coin...													$NC"
        echo -e "$CYAN ------------------------------------------------------------------------------- 	$NC"
        echo
        sudo find $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/ -type d -exec chmod 777 {} \;
        sudo find $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/ -type f -exec chmod 777 {} \;
        
        ./configure CPPFLAGS="-I$STORAGE_ROOT/daemon_builder/berkeley/db6.2/include -O2" LDFLAGS="-L$STORAGE_ROOT/daemon_builder/berkeley/db6.2/lib" --with-incompatible-bdb --without-gui --disable-tests
        echo
		clear;
        echo -e "$CYAN ------------------------------------------------------------------------------- 	$NC"
        echo -e "$GREEN   Starting make coin...															$NC"
        echo -e "$CYAN ------------------------------------------------------------------------------- 	$NC"
        echo
        sudo find $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/ -type d -exec chmod 777 {} \;
        sudo find $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/ -type f -exec chmod 777 {} \;
        
        # make install
        TMP=$(tempfile)
        make -j${NPROC} 2>&1 | tee $TMP
        OUTPUT=$(cat $TMP)
        echo $OUTPUT
        rm $TMP
    fi
    
    # Build the coin under UTIL directory with BUILD.SH file
    if [[ ("$buildutil" == "true") ]]; then
        echo
		clear;
        echo -e "$CYAN ------------------------------------------------------------------------------- 	$NC"
        echo -e "$GREEN   Starting Building $MAGENTA ${coin^^} $NC$GREEN using UTIL directory contains BUILD.SH	$NC"
        echo -e "$CYAN ------------------------------------------------------------------------------- 	$NC"
        echo
        basedir=$(pwd)
        
        FILEAUTOGEN=$STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/autogen.sh
        if [[ ! -f "$FILEAUTOGEN" ]]; then
            echo -e "$YELLOW"
            find . -maxdepth 1 -type d \( -perm -1 -o \( -perm -10 -o -perm -100 \) \) -printf "%f\n"
            echo -e "$NC$MAGENTA"
            read -r -e -p "Where is the folder that contains the installation ${coin^^}, example bitcoin :" repotherinstall
            echo -e "$NC"
			clear;
            echo -e "$CYAN ------------------------------------------------------------------------------- 	$NC"
            echo -e "$GREEN   Moving files and Starting Building coin $MAGENTA ${coin^^} 					$NC"
            echo -e "$CYAN ------------------------------------------------------------------------------- 	$NC"
            echo
            
            sudo mv $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/${repotherinstall}/* $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}
            
        fi
        
        sh autogen.sh
        
        find . -maxdepth 1 -type d \( -perm -1 -o \( -perm -10 -o -perm -100 \) \) -printf "%f\n"
        read -r -e -p "where is the folder that contains the BUILD.SH installation file, example xxutil :" reputil
        cd $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/${reputil}
        echo $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/${reputil}
        sudo find $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/ -type d -exec chmod 777 {} \;
        sudo find $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/ -type f -exec chmod 777 {} \;
        
        bash build.sh -j$(nproc)
        
        if [[ ! -e "$STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/${reputil}/fetch-params.sh" ]]; then
            echo "fetch-params.sh not found skipping"
        else
            sudo find $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/ -type d -exec chmod 777 {} \;
            sudo find $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/ -type f -exec chmod 777 {} \;
            sh fetch-params.sh
        fi
    fi
    
else
    
    # Build the coin under cmake
    if [[ ("$cmake" == "true") ]]; then
        clear
        DEPENDS="$STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/depends"
        
        # Build the coin under depends present
        if [ -d "$DEPENDS" ]; then
            echo
            echo
            echo -e "$CYAN => Building using cmake with DEPENDS directory... $NC"
            echo
            
            
            echo
            echo
            read -r -e -p "Hide LOG from to Work Coin ? [y/N] :" ifhidework
            echo
            
            # Executing make on depends directory
            echo
            echo -e "$YELLOW => executing make on depends directory... $NC"
            echo
            
            cd $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/depends
            if [[ ("$ifhidework" == "y" || "$ifhidework" == "Y") ]]; then
                # make install
                TMP=$(tempfile)
                hide_output make -j${NPROC} 2>&1 | tee $TMP
                OUTPUT=$(cat $TMP)
                echo $OUTPUT
                rm $TMP
            else
                echo
				clear;
                echo -e "$CYAN --------------------------------------------------------------------------- 	$NC"
                echo -e "$GREEN   Starting make coin...														$NC"
                echo -e "$CYAN --------------------------------------------------------------------------- 	$NC"
                echo
                sudo find $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/ -type d -exec chmod 777 {} \;
                sudo find $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/ -type f -exec chmod 777 {} \;
                
                # make install
                TMP=$(tempfile)
                make -j${NPROC} 2>&1 | tee $TMP
                OUTPUT=$(cat $TMP)
                echo $OUTPUT
                rm $TMP
            fi
            echo
            echo
            echo -e "$GREEN Done...$NC"
            
            # Building autogen....
            echo
			clear;
            echo -e "$CYAN --------------------------------------------------------------------------- 	$NC"
            echo -e "$GREEN   Starting Building coin $MAGENTA ${coin^^} $NC using autogen...		$NC"
            echo -e "$CYAN --------------------------------------------------------------------------- 	$NC"
            echo
            
            cd $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}
            if [[ ("$ifhidework" == "y" || "$ifhidework" == "Y") ]]; then
                hide_output sh autogen.sh
            else
                sh autogen.sh
            fi
            echo
            echo
            echo -e "$GREEN Done...$NC"
            
            # Configure with your platform....
            if [ -d "$DEPENDS/i686-pc-linux-gnu" ]; then
                echo
				clear;
                echo -e "$YELLOW => Configure with i686-pc-linux-gnu... $NC"
                echo
                sudo find $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/ -type d -exec chmod 777 {} \;
                sudo find $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/ -type f -exec chmod 777 {} \;
                
                if [[ ("$ifhidework" == "y" || "$ifhidework" == "Y") ]]; then
                    hide_output ./configure --with-incompatible-bdb --prefix=`pwd`/depends/i686-pc-linux-gnu
                else
                    ./configure --with-incompatible-bdb --prefix=`pwd`/depends/i686-pc-linux-gnu
                fi
                elif [ -d "$DEPENDS/x86_64-pc-linux-gnu/" ]; then
                echo
                echo -e "$YELLOW => Configure with x86_64-pc-linux-gnu... $NC"
                echo
                sudo find $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/ -type d -exec chmod 777 {} \;
                sudo find $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/ -type f -exec chmod 777 {} \;
                
                if [[ ("$ifhidework" == "y" || "$ifhidework" == "Y") ]]; then
                    hide_output ./configure --with-incompatible-bdb --prefix=`pwd`/depends/x86_64-pc-linux-gnu
                else
                    ./configure --with-incompatible-bdb --prefix=`pwd`/depends/x86_64-pc-linux-gnu
                fi
                elif [ -d "$DEPENDS/i686-w64-mingw32/" ]; then
                echo
				clear;
                echo -e "$YELLOW => Configure with i686-w64-mingw32... $NC"
                echo
                sudo find $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/ -type d -exec chmod 777 {} \;
                sudo find $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/ -type f -exec chmod 777 {} \;
                
                if [[ ("$ifhidework" == "y" || "$ifhidework" == "Y") ]]; then
                    hide_output ./configure --with-incompatible-bdb --prefix=`pwd`/depends/i686-w64-mingw32
                else
                    ./configure --with-incompatible-bdb --prefix=`pwd`/depends/i686-w64-mingw32
                fi
                elif [ -d "$DEPENDS/x86_64-w64-mingw32/" ]; then
                echo
				clear;
                echo -e "$YELLOW => Configure with x86_64-w64-mingw32... $NC"
                echo
                sudo find $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/ -type d -exec chmod 777 {} \;
                sudo find $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/ -type f -exec chmod 777 {} \;
                
                if [[ ("$ifhidework" == "y" || "$ifhidework" == "Y") ]]; then
                    hide_output ./configure --with-incompatible-bdb --prefix=`pwd`/depends/x86_64-w64-mingw32
                else
                    ./configure --with-incompatible-bdb --prefix=`pwd`/depends/x86_64-w64-mingw32
                fi
                elif [ -d "$DEPENDS/x86_64-apple-darwin14/" ]; then
                echo
				clear;
                echo -e "$YELLOW => Configure with x86_64-apple-darwin14... $NC"
                echo
                sudo find $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/ -type d -exec chmod 777 {} \;
                sudo find $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/ -type f -exec chmod 777 {} \;
                
                if [[ ("$ifhidework" == "y" || "$ifhidework" == "Y") ]]; then
                    hide_output ./configure --with-incompatible-bdb --prefix=`pwd`/depends/x86_64-apple-darwin14
                else
                    ./configure --with-incompatible-bdb --prefix=`pwd`/depends/x86_64-apple-darwin14
                fi
                elif [ -d "$DEPENDS/arm-linux-gnueabihf/" ]; then
                echo
                echo -e "$YELLOW => Configure with arm-linux-gnueabihf... $NC"
                echo
                sudo find $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/ -type d -exec chmod 777 {} \;
                sudo find $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/ -type f -exec chmod 777 {} \;
                
                if [[ ("$ifhidework" == "y" || "$ifhidework" == "Y") ]]; then
                    hide_output ./configure --with-incompatible-bdb --prefix=`pwd`/depends/arm-linux-gnueabihf
                else
                    ./configure --with-incompatible-bdb --prefix=`pwd`/depends/arm-linux-gnueabihf
                fi
                elif [ -d "$DEPENDS/aarch64-linux-gnu/" ]; then
                echo
				clear;
                echo -e "$YELLOW => Configure with aarch64-linux-gnu... $NC"
                echo
                sudo find $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/ -type d -exec chmod 777 {} \;
                sudo find $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/ -type f -exec chmod 777 {} \;
                
                if [[ ("$ifhidework" == "y" || "$ifhidework" == "Y") ]]; then
                    hide_output ./configure --with-incompatible-bdb --prefix=`pwd`/depends/aarch64-linux-gnu
                else
                    ./configure --with-incompatible-bdb --prefix=`pwd`/depends/aarch64-linux-gnu
                fi
            fi
            echo
            echo
            echo -e "$GREEN Done...$NC"
            
            # Executing make to finalize....
            echo
			clear;
            echo -e "$YELLOW => Executing make to finalize... $NC"
            echo
            sudo find $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/ -type d -exec chmod 777 {} \;
            sudo find $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/ -type f -exec chmod 777 {} \;
            
            if [[ ("$ifhidework" == "y" || "$ifhidework" == "Y") ]]; then
                # make install
                TMP=$(tempfile)
                hide_output make -j${NPROC} 2>&1 | tee $TMP
                OUTPUT=$(cat $TMP)
                echo $OUTPUT
                rm $TMP
            else
                echo
				clear;
                echo -e "$CYAN --------------------------------------------------------------------------- 	$NC"
                echo -e "$GREEN   Starting make coin...														$NC"
                echo -e "$CYAN --------------------------------------------------------------------------- 	$NC"
                echo
                sudo find $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/ -type d -exec chmod 777 {} \;
                sudo find $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/ -type f -exec chmod 777 {} \;
                
                # make install
                TMP=$(tempfile)
                make -j${NPROC} 2>&1 | tee $TMP
                OUTPUT=$(cat $TMP)
                echo $OUTPUT
                rm $TMP
            fi
            echo
            echo
            echo -e "$GREEN Done...$NC"
        else
            echo
			clear;
            echo -e "$CYAN --------------------------------------------------------------------------- 	$NC"
            echo -e "$GREEN   Starting Building coin $MAGENTA ${coin^^} $NC using Cmake method	$NC"
            echo -e "$CYAN --------------------------------------------------------------------------- 	$NC"
            echo
            
            cd $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir} && git submodule init && git submodule update
            
            echo
			clear;
            echo -e "$CYAN --------------------------------------------------------------------------- 	$NC"
            echo -e "$GREEN   Starting make coin...														$NC"
            echo -e "$CYAN --------------------------------------------------------------------------- 	$NC"
            echo
            sudo find $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/ -type d -exec chmod 777 {} \;
            sudo find $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/ -type f -exec chmod 777 {} \;
            
            # make install
            TMP=$(tempfile)
            make -j${NPROC} 2>&1 | tee $TMP
            OUTPUT=$(cat $TMP)
            echo $OUTPUT
            rm $TMP
            
        fi
    fi
    
    # Build the coin under unix
    if [[ ("$unix" == "true") ]]; then
        echo
		clear;
        echo -e "$CYAN ----------------------------------------------------------------------------------- 	$NC"
        echo -e "$GREEN   Starting Building coin $MAGENTA ${coin^^} $NC	using makefile.unix method	$NC"
        echo -e "$CYAN ----------------------------------------------------------------------------------- 	$NC"
        echo
        cd $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/src
        
        if [[ ! -e "$STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/src/obj" ]]; then
            mkdir -p $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/src/obj
        else
            echo "Hey the developer did his job and the src/obj dir is there!"
        fi
        
        if [[ ! -e "$STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/src/obj/zerocoin" ]]; then
            mkdir -p $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/src/obj/zerocoin
        else
            echo  "Wow even the /src/obj/zerocoin is there! Good job developer!"
        fi
        
        cd $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/src/leveldb
        sudo chmod +x build_detect_platform
        echo
		clear;
        echo -e "$CYAN ------------------------------------------------------------------------------- 	$NC"
        echo -e "$GREEN   Starting make clean...														$NC"
        echo -e "$CYAN ------------------------------------------------------------------------------- 	$NC"
        echo
        sudo find $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/ -type d -exec chmod 777 {} \;
        sudo find $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/ -type f -exec chmod 777 {} \;
        
        sudo make clean
        echo
		clear;
        echo -e "$CYAN ------------------------------------------------------------------------------- 	$NC"
        echo -e "$GREEN   Starting precompiling with make depends libs*									$NC"
        echo -e "$CYAN ------------------------------------------------------------------------------- 	$NC"
        echo
        sudo find $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/ -type d -exec chmod 777 {} \;
        sudo find $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/ -type f -exec chmod 777 {} \;
        
        sudo make libleveldb.a libmemenv.a
        cd $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/src
        sudo find $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/ -type d -exec chmod 777 {} \;
        sudo find $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/ -type f -exec chmod 777 {} \;
        
        sed -i '/USE_UPNP:=0/i BDB_LIB_PATH = '${absolutepath}'/'${installtoserver}'/berkeley/db4/lib\nBDB_INCLUDE_PATH = '${absolutepath}'/'${installtoserver}'/berkeley/db4/include\nOPENSSL_LIB_PATH = '${absolutepath}'/'${installtoserver}'/openssl/lib\nOPENSSL_INCLUDE_PATH = '${absolutepath}'/'${installtoserver}'/openssl/include' makefile.unix
        sed -i '/USE_UPNP:=1/i BDB_LIB_PATH = '${absolutepath}'/'${installtoserver}'/berkeley/db4/lib\nBDB_INCLUDE_PATH = '${absolutepath}'/'${installtoserver}'/berkeley/db4/include\nOPENSSL_LIB_PATH = '${absolutepath}'/'${installtoserver}'/openssl/lib\nOPENSSL_INCLUDE_PATH = '${absolutepath}'/'${installtoserver}'/openssl/include' makefile.unix
        echo
		clear;
        echo -e "$CYAN ------------------------------------------------------------------------------- 	$NC"
        echo -e "$GREEN   Starting compiling with makefile.unix											$NC"
        echo -e "$CYAN ------------------------------------------------------------------------------- 	$NC"
        
        # make install
        TMP=$(tempfile)
        make -j${NPROC} -f makefile.unix USE_UPNP=- 2>&1 | tee $TMP
        OUTPUT=$(cat $TMP)
        echo $OUTPUT
        rm $TMP
    fi
fi

if [[ "$precompiled" == "true" ]]; then

    COINTARGZ=$(find . -type f -name "*.tar.gz")
    COINTGZ=$(find . -type f -name "*.tgz")
    COINZIP=$(find . -type f -name "*.zip")
    COIN7Z=$(find . -type f -name "*.7z")

    if [[ -f "$COINZIP" ]]; then
        hide_output sudo unzip -q "$COINZIP"
    elif [[ -f "$COINTARGZ" ]]; then
        hide_output sudo tar xzvf "$COINTARGZ"
    elif [[ -f "$COINTGZ" ]]; then
        hide_output sudo tar xzvf "$COINTGZ"
    elif [[ -f "$COIN7Z" ]]; then
        hide_output sudo 7z x "$COIN7Z"
    else
        echo -e "$RED => No valid compressed files found (.zip, .tar.gz, .tgz, or .7z).$NC"
        exit 1
    fi

    echo
    echo -e "$CYAN === Searching for wallet files ===$NC"
    echo

    # Find the directory containing wallet files
    WALLET_DIR=$(find . -type d -exec sh -c '
        cd "{}" 2>/dev/null && 
        if find . -maxdepth 1 -type f -executable \( -name "*coind" -o -name "*d" -o -name "*daemon" \) 2>/dev/null | grep -q .; then
            pwd
            exit 0
        fi' \; | head -n 1)

    if [[ -z "$WALLET_DIR" ]]; then
        echo -e "$RED => Could not find directory containing wallet files.$NC"
        exit 1
    fi

    echo -e "$CYAN === Found wallet directory: $YELLOW$WALLET_DIR $NC"
    cd $WALLET_DIR

    # Now search for executables in the correct directory
    COINDFIND=$(find ~+ -type f -executable \( -name "*coind" -o -name "*d" -o -name "*daemon" \) ! -name "*.sh" ! -name "README*" ! -name "*.md" ! -name "*.txt" 2>/dev/null | head -n 1)
    COINCLIFIND=$(find ~+ -type f -executable -name "*-cli" ! -name "*.sh" ! -name "README*" ! -name "*.md" ! -name "*.txt" 2>/dev/null | head -n 1)
    COINTXFIND=$(find ~+ -type f -executable -name "*-tx" ! -name "*.sh" ! -name "README*" ! -name "*.md" ! -name "*.txt" 2>/dev/null | head -n 1)
    COINUTILFIND=$(find ~+ -type f -executable -name "*-util" ! -name "*.sh" ! -name "README*" ! -name "*.md" ! -name "*.txt" 2>/dev/null | head -n 1)
    COINHASHFIND=$(find ~+ -type f -executable -name "*-hash" ! -name "*.sh" ! -name "README*" ! -name "*.md" ! -name "*.txt" 2>/dev/null | head -n 1)
    COINWALLETFIND=$(find ~+ -type f -executable -name "*-wallet" ! -name "*.sh" ! -name "README*" ! -name "*.md" ! -name "*.txt" 2>/dev/null | head -n 1)
    COINUTILFIND=$(find ~+ -type f -executable -name "*-util" ! -name "*.sh" ! -name "README*" ! -name "*.md" ! -name "*.txt" 2>/dev/null | head -n 1)
    COINQTFIND=$(find . -type f -executable -name "*-qt" 2>/dev/null)

    declare -A wallet_files_found
    declare -A wallet_files_not_found
    
    if [[ -n "$COINDFIND" ]]; then
        wallet_files_found["Daemon"]=$(basename "$COINDFIND")
    else
        wallet_files_not_found["Daemon"]="true"
    fi

    [[ -n "$COINCLIFIND" ]] && wallet_files_found["CLI"]=$(basename "$COINCLIFIND") || wallet_files_not_found["CLI"]="true"
    [[ -n "$COINTXFIND" ]] && wallet_files_found["TX"]=$(basename "$COINTXFIND") || wallet_files_not_found["TX"]="true"
    [[ -n "$COINUTILFIND" ]] && wallet_files_found["Util"]=$(basename "$COINUTILFIND") || wallet_files_not_found["Util"]="true"
    [[ -n "$COINHASHFIND" ]] && wallet_files_found["Hash"]=$(basename "$COINHASHFIND") || wallet_files_not_found["Hash"]="true"
    [[ -n "$COINWALLETFIND" ]] && wallet_files_found["Wallet"]=$(basename "$COINWALLETFIND") || wallet_files_not_found["Wallet"]="true"
    [[ -n "$COINQTFIND" ]] && wallet_files_found["QT"]=$(basename "$COINQTFIND") || wallet_files_not_found["QT"]="true"
    [[ -n "$COINUTILSFIND" ]] && wallet_files_found["Utils"]=$(basename "$COINUTILSFIND") || wallet_files_not_found["Utils"]="true"

    echo -e "$GREEN === Found Wallet Files ===$NC"
    echo
    for type in "${!wallet_files_found[@]}"; do
        echo -e "$type: $YELLOW${wallet_files_found[$type]}$NC"
        sleep 0.5
    done

    echo
    echo -e "$RED => === Missing Wallet Files in zip/tar/7z file ===$NC"
    echo
    for type in "${!wallet_files_not_found[@]}"; do
        echo -e "$type: Not found"
        sleep 0.5
    done

    if [[ -n "$COINDFIND" ]]; then
    echo
        echo -e "$GREEN => Found Daemon: $YELLOW${wallet_files_found["Daemon"]}$NC"
    else
        echo
        echo -e "$RED=> Could not find daemon executable. Installation failed.$NC"
        echo
        exit 1
    fi

    echo -e "$CYAN === Install Directory ===$NC"
    echo -e "Executables will be installed to: $YELLOW$HOME/daemon_builder/src$NC"

    echo
    coind=$(basename "$COINDFIND")
    [[ -n "$COINCLIFIND" ]] && coincli=$(basename "$COINCLIFIND")
    [[ -n "$COINTXFIND" ]] && cointx=$(basename "$COINTXFIND") 
    [[ -n "$COINUTILFIND" ]] && coinutil=$(basename "$COINUTILFIND")
    [[ -n "$COINHASHFIND" ]] && coinhash=$(basename "$COINHASHFIND")
    [[ -n "$COINWALLETFIND" ]] && coinwallet=$(basename "$COINWALLETFIND")

fi

clear

if [[ "$precompiled" == "true" ]]; then

    cd $WALLET_DIR
    
    echo

    echo -e "$CYAN === List of files in $WALLET_DIR: $NC"
    echo
    for type in "${!wallet_files_found[@]}"; do
        echo -e "$type: $YELLOW${wallet_files_found[$type]}$NC"
    done
    echo
    echo -e "$CYAN --------------------------------------------------------------------------------------- 	$NC"
    echo

    read -r -e -p "please enter the coind name from the directory above, example $coind :" coind
    echo
    read -r -e -p "Is there a $coincli, example $coincli [y/N] :" ifcoincli
    if [[ ("$ifcoincli" == "y" || "$ifcoincli" == "Y") ]]; then
        read -r -e -p "Please enter the coin-cli name :" ifcoincli
    fi

    echo
    read -r -e -p "Is there a coin-tx [y/N] :" ifcointx
    if [[ ("$ifcointx" == "y" || "$ifcointx" == "Y") ]]; then
        read -r -e -p "Please enter the coin-tx name :" ifcointx
    fi

    echo
    read -r -e -p "Is there a coin-util [y/N] :" ifcoinutil
    if [[ ("$ifcoinutil" == "y" || "$ifcoinutil" == "Y") ]]; then
        read -r -e -p "Please enter the coin-util name :" ifcoinutil
    fi

    echo
    read -r -e -p "Is there a coin-wallet [y/N] :" ifcoinwallet
    if [[ ("$ifcoinwallet" == "y" || "$ifcoinwallet" == "Y") ]]; then
        read -r -e -p "Please enter the coin-wallet name :" ifcoinwallet
    fi

    echo
    read -r -e -p "Is there a coin-qt [y/N] :" ifcoinqt
    if [[ ("$ifcoinqt" == "y" || "$ifcoinqt" == "Y") ]]; then
        read -r -e -p "Please enter the coin-qt name :" ifcoinqt
    fi



    echo
    echo -e "$CYAN --------------------------------------------------------------------------------------- 	$NC"
    echo
    
    FILECOIN=/usr/bin/${coind}
    if [[ -f "$FILECOIN" ]]; then
        DAEMOND="true"
        SERVICE="${coind}"
        if pgrep -x "$SERVICE" >/dev/null; then
            if [[ ("${YIIMPCONF}" == "true") ]]; then
                if [[ ("$ifcoincli" == "y" || "$ifcoincli" == "Y") ]]; then
                    "${coincli}" -datadir=$STORAGE_ROOT/wallets/."${coind::-1}" -conf="${coind::-1}".conf stop
                else
                    "${coind}" -datadir=$STORAGE_ROOT/wallets/."${coind::-1}" -conf="${coind::-1}".conf stop
                fi
            else
                if [[ ("$ifcoincli" == "y" || "$ifcoincli" == "Y") ]]; then
                    "${coincli}" -datadir=${absolutepath}/wallets/."${coind::-1}" -conf="${coind::-1}".conf stop
                else
                    "${coind}" -datadir=${absolutepath}/wallets/."${coind::-1}" -conf="${coind::-1}".conf stop
                fi
            fi
            echo -e "$CYAN --------------------------------------------------------------------------- $NC"
            secstosleep=$((1 * 20))
            while [ $secstosleep -gt 0 ]; do
                echo -ne "$GREEN	STOP THE DAEMON => $YELLOW${coind}$GREEN Sleep $CYAN$secstosleep$GREEN ...$NC\033[0K\r"
                
                : $((secstosleep--))
            done
            echo -e "$CYAN --------------------------------------------------------------------------- $NC $GREEN"
            echo -e "$GREEN Done... $NC$"
            echo -e "$NC$CYAN --------------------------------------------------------------------------- $NC"
            echo
        fi
    fi
fi

clear

# Strip and copy to /usr/bin
if [[ ("$precompiled" == "true") ]]; then
    cd $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/${repzipcoin}/
    
    COINDFIND=$(find ~+ -type f -name "*d")
    sleep 0.5
    COINCLIFIND=$(find ~+ -type f -name "*-cli")
    sleep 0.5
    COINTXFIND=$(find ~+ -type f -name "*-tx")
    sleep 0.5
    COINUTILFIND=$(find ~+ -type f -name "*-util")
    sleep 0.5
    COINHASHFIND=$(find ~+ -type f -name "*-hash")
    sleep 0.5
    COINWALLETFIND=$(find ~+ -type f -name "*-wallet")
    
    
    if [[ -f "$COINDFIND" ]]; then
        coind=$(basename $COINDFIND)
        
        if [[ -f "$COINCLIFIND" ]]; then
            coincli=$(basename $COINCLIFIND)
        fi
        
        FILECOIN=/usr/bin/${coind}
        if [[ -f "$FILECOIN" ]]; then
            DAEMOND="true"
            SERVICE="${coind}"
            if pgrep -x "$SERVICE" >/dev/null; then
                if [[ ("${YIIMPCONF}" == "true") ]]; then
                    if [[ -f "$COINCLIFIND" ]]; then
                        "${coincli}" -datadir=$STORAGE_ROOT/wallets/."${coind::-1}" -conf="${coind::-1}".conf stop
                    else
                        "${coind}" -datadir=$STORAGE_ROOT/wallets/."${coind::-1}" -conf="${coind::-1}".conf stop
                    fi
                else
                    if [[ -f "${COINCLIFIND}" ]]; then
                        "${coincli}" -datadir=${absolutepath}/wallets/."${coind::-1}" -conf="${coind::-1}".conf stop
                    else
                        "${coind}" -datadir=${absolutepath}/wallets/."${coind::-1}" -conf="${coind::-1}".conf stop
                    fi
                fi
                echo -e "$CYAN --------------------------------------------------------------------------- $NC"
                secstosleep=$((1 * 20))
                while [ $secstosleep -gt 0 ]; do
                    echo -ne "$GREEN	STOP THE DAEMON => $YELLOW${coind}$GREEN Sleep $CYAN$secstosleep$GREEN ...$NC"
                    
                    : $((secstosleep--))
                done
                echo -e "$CYAN --------------------------------------------------------------------------- $NC $GREEN"
                echo -e "$GREEN Done... $NC$"
                echo -e "$NC$CYAN --------------------------------------------------------------------------- $NC"
                echo
            fi
        fi
        
        sudo strip $COINDFIND
        
        sudo cp $COINDFIND /usr/bin
        sudo chmod +x /usr/bin/${coind}
        coindmv=true
        
        echo
        echo -e "$CYAN ----------------------------------------------------------------------------------- $NC"
        echo
        echo -e "$GREEN  ${coind} moving to =>$YELLOW /usr/bin/$NC${coind} $NC"
        
        clear
        
    fi
    
    if [[ -f "$COINCLIFIND" ]]; then
        sudo strip $COINCLIFIND
        
        sudo cp $COINCLIFIND /usr/bin
        sudo chmod +x /usr/bin/${coincli}
        coinclimv=true
        
        echo -e "$GREEN  Coin-cli moving to => /usr/bin/$NC$YELLOW${coincli} $NC"
        
    fi
    
    if [[ -f "$COINTXFIND" ]]; then
        cointx=$(basename $COINTXFIND)
        sudo strip $COINTXFIND
        
        sudo cp $COINTXFIND /usr/bin
        sudo chmod +x /usr/bin/${cointx}
        cointxmv=true
        
        echo -e "$GREEN  Coin-tx moving to => /usr/bin/$NC$YELLOW${cointx} $NC"
        
    fi
    
    if [[ -f "$COINUTILFIND" ]]; then
        coinutil=$(basename $COINUTILFIND)
        sudo strip $COINUTILFIND
        
        sudo cp $COINUTILFIND /usr/bin
        sudo chmod +x /usr/bin/${coinutil}
        coinutilmv=true
        
        echo -e "$GREEN  Coin-tx moving to => /usr/bin/$NC$YELLOW${coinutil} $NC"
        
    fi
    
    if [[ -f "$COINHASHFIND" ]]; then
        coinhash=$(basename $COINHASHFIND)
        sudo strip $COINHASHFIND
        
        sudo cp $COINHASHFIND /usr/bin
        sudo chmod +x /usr/bin/${coinhash}
        coinhashmv=true
        
        echo -e "$GREEN  Coin-hash moving to => /usr/bin/$NC$YELLOW${coinwallet} $NC"
        
    fi
    
    if [[ -f "$COINWALLETFIND" ]]; then
        coinwallet=$(basename $COINWALLETFIND)
        sudo strip $COINWALLETFIND
        
        sudo cp $COINWALLETFIND /usr/bin
        sudo chmod +x /usr/bin/${coinwallet}
        coinwalletmv=true
        
        print_success "Installed ${coinwallet} binary to /usr/bin/${coinwallet}"
    else
        print_error "Precompiled binary not found"
    fi
    echo
    echo -e "$CYAN --------------------------------------------------------------------------------------- $NC"
    echo
else
    echo
    echo -e "$CYAN --------------------------------------------------------------------------------------- $NC"
    echo
    cd $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/src
    print_divider "Detecting executables in $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/src"
    
    # Now search for executables in the correct directory
    COINDFIND=$(find ~+ -type f -executable \( -name "*coind" -o -name "*d" -o -name "*daemon" \) ! -name "*.sh" ! -name "README*" ! -name "*.md" ! -name "*.txt" 2>/dev/null | head -n 1)
    sleep 0.5
    COINCLIFIND=$(find ~+ -type f -executable -name "*-cli" ! -name "*.sh" ! -name "README*" ! -name "*.md" ! -name "*.txt" 2>/dev/null | head -n 1)
    sleep 0.5
    COINTXFIND=$(find ~+ -type f -executable -name "*-tx" ! -name "*.sh" ! -name "README*" ! -name "*.md" ! -name "*.txt" 2>/dev/null | head -n 1)
    sleep 0.5
    COINUTILFIND=$(find ~+ -type f -executable -name "*-util" ! -name "*.sh" ! -name "README*" ! -name "*.md" ! -name "*.txt" 2>/dev/null | head -n 1)
    sleep 0.5
    COINHASHFIND=$(find ~+ -type f -executable -name "*-hash" ! -name "*.sh" ! -name "README*" ! -name "*.md" ! -name "*.txt" 2>/dev/null | head -n 1)
    sleep 0.5
    COINWALLETFIND=$(find ~+ -type f -executable -name "*-wallet" ! -name "*.sh" ! -name "README*" ! -name "*.md" ! -name "*.txt" 2>/dev/null | head -n 1)
    sleep 0.5
    COINQTFIND=$(find . -type f -executable -name "*-qt" 2>/dev/null)

    declare -A wallet_files_found
    declare -A wallet_files_not_found
    
    if [[ -n "$COINDFIND" ]]; then
        wallet_files_found["Daemon"]=$(basename "$COINDFIND")
        coind=$(basename "$COINDFIND")
    else
        wallet_files_not_found["Daemon"]="true"
    fi

    if [[ -n "$COINCLIFIND" ]]; then
        wallet_files_found["CLI"]=$(basename "$COINCLIFIND")
        coincli=$(basename "$COINCLIFIND")
    else
        wallet_files_not_found["CLI"]="true"
    fi

    if [[ -n "$COINTXFIND" ]]; then
        wallet_files_found["TX"]=$(basename "$COINTXFIND")
        cointx=$(basename "$COINTXFIND")
    else
        wallet_files_not_found["TX"]="true"
    fi

    if [[ -n "$COINUTILFIND" ]]; then
        wallet_files_found["Util"]=$(basename "$COINUTILFIND")
        coinutil=$(basename "$COINUTILFIND")
    else
        wallet_files_not_found["Util"]="true"
    fi

    if [[ -n "$COINHASHFIND" ]]; then
        wallet_files_found["Hash"]=$(basename "$COINHASHFIND")
        coinhash=$(basename "$COINHASHFIND")
    else
        wallet_files_not_found["Hash"]="true"
    fi

    if [[ -n "$COINWALLETFIND" ]]; then
        wallet_files_found["Wallet"]=$(basename "$COINWALLETFIND")
        coinwallet=$(basename "$COINWALLETFIND")
    else
        wallet_files_not_found["Wallet"]="true"
    fi

    if [[ -n "$COINQTFIND" ]]; then
        wallet_files_found["QT"]=$(basename "$COINQTFIND")
        coinqt=$(basename "$COINQTFIND")
    else
        wallet_files_not_found["QT"]="true"
    fi

    echo -e "$GREEN === Found Wallet Files ===$NC"
    echo
    for type in "${!wallet_files_found[@]}"; do
        echo -e "$type: $YELLOW${wallet_files_found[$type]}$NC"
        sleep 0.5
    done

    echo
    echo -e "$RED === Missing Wallet Files ===$NC"
    echo
    for type in "${!wallet_files_not_found[@]}"; do
        echo -e "$type: Not found"
        sleep 0.5
    done

    if [[ -n "$COINDFIND" ]]; then
        echo
        echo -e "$GREEN => Found Daemon: $YELLOW${wallet_files_found["Daemon"]}$NC"
    else
        echo
        echo -e "$RED=> Could not find daemon executable. Installation failed.$NC"
        echo
        exit 1
    fi

    echo -e "$CYAN === Install Directory ===$NC"
    echo -e "Executables will be installed to: $YELLOW/usr/bin$NC"
    echo

    echo -e "$GREEN  Daemon moving to => /usr/bin/$NC$YELLOW${coind} $NC"
    
    sudo cp -r $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/src/${coind} /usr/bin
    sudo strip /usr/bin/${coind}
    coindmv=true
    
    if [[ -n "$COINCLIFIND" ]]; then
        echo -e "$GREEN  CLI moving to => /usr/bin/$NC$YELLOW${coincli} $NC"
        sudo cp -r $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/src/${coincli} /usr/bin
        sudo strip /usr/bin/${coincli}
        coinclimv=true
    fi
    
    if [[ -n "$COINTXFIND" ]]; then
        echo -e "$GREEN  TX moving to => /usr/bin/$NC$YELLOW${cointx} $NC"
        sudo cp -r $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/src/${cointx} /usr/bin
        sudo strip /usr/bin/${cointx}
        cointxmv=true
    fi
    
    if [[ -n "$COINUTILFIND" ]]; then
        echo -e "$GREEN  UTIL moving to => /usr/bin/$NC$YELLOW${coinutil} $NC"
        sudo cp -r $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/src/${coinutil} /usr/bin
        sudo strip /usr/bin/${coinutil}
        coinutilmv=true
    fi
    
    if [[ -n "$COINHASHFIND" ]]; then
        echo -e "$GREEN  HASH moving to => /usr/bin/$NC$YELLOW${coinhash} $NC"
        sudo cp -r $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/src/${coinhash} /usr/bin
        sudo strip /usr/bin/${coinhash}
        coinhashmv=true
    fi
    
    if [[ -n "$COINWALLETFIND" ]]; then
        echo -e "$GREEN  WALLET moving to => /usr/bin/$NC$YELLOW${coinwallet} $NC"
        sudo cp -r $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/src/${coinwallet} /usr/bin
        sudo strip /usr/bin/${coinwallet}
        coinwalletmv=true
    fi
    
    if [[ -n "$COINQTFIND" ]]; then
        echo -e "$GREEN  QT moving to => /usr/bin/$NC$YELLOW${coinqt} $NC"
        sudo cp -r $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/src/${coinqt} /usr/bin
        sudo strip /usr/bin/${coinqt}
        coinqtmv=true
    fi
    
    echo
    echo -e "$CYAN --------------------------------------------------------------------------------------- $NC"
    echo
fi

if [[ "$YIIMPCONF" == "true" ]]; then
    # Make the new wallet folder have user paste the coin.conf and finally start the daemon
    if [[ ! -e "$STORAGE_ROOT/wallets" ]]; then
        sudo mkdir -p $STORAGE_ROOT/wallets
    fi
    
    sudo setfacl -m u:${USERSERVER}:rwx $STORAGE_ROOT/wallets
    mkdir -p "$STORAGE_ROOT/wallets/.${coind::-1}"
    
    if [[ "$coinwalletmv" == "true" ]]; then
        echo
        clear
        echo -e "$CYAN ----------------------------------------------------------------------------------- 	$NC"
        echo -e "$GREEN   Creating WALLET.DAT to => ${STORAGE_ROOT}/wallets/.${coind%?}/wallet.dat          $NC"
        echo -e "$CYAN ----------------------------------------------------------------------------------- 	$NC"
        echo
        "${coinwallet}" -datadir="${STORAGE_ROOT}/wallets/.${coind%?}" -wallet=. create
    fi
fi

if [[ ("$DAEMOND" != "true") ]]; then
    echo
    clear
    echo -e "$CYAN --------------------------------------------------------------------------------------- 	$NC"
    echo -e "$GREEN   Adding dedicated port to ${coin^^}$NC"
    echo -e "$CYAN --------------------------------------------------------------------------------------- 	$NC"
    echo
    
    addport "CREATECOIN" "${coin^^}" "${coinalgo}"
    
    source $STORAGE_ROOT/daemon_builder/.addport.cnf
    
    ADDPORTCONF=$STORAGE_ROOT/daemon_builder/.addport.cnf
    
    if [[ -f "$ADDPORTCONF" ]]; then
        if [[ "${YIIMPCONF}" == "true" ]]; then
            echo '
			# Your coin name is = '""''"${coin^^}"''""'
			# Your coin algo is = '""''"${COINALGO}"''""'
			# Your dedicated port is = '""''"${COINPORT}"''""'
			# Please adding dedicated port in line blocknotify= replace :XXXX to '""''"${COINPORT}"''""'
            ' | sudo -E tee $STORAGE_ROOT/wallets/."${coind::-1}"/${coind::-1}.conf >/dev/null 2>&1;
        else
            echo '
			# Your coin name is = '""''"${coin^^}"''""'
			# Your coin algo is = '""''"${COINALGO}"''""'
			# Your dedicated port is = '""''"${COINPORT}"''""'
			# Please adding dedicated port in line blocknotify= replace :XXXX to '""''"${COINPORT}"''""'
            ' | sudo -E tee ${absolutepath}/wallets/."${coind::-1}"/${coind::-1}.conf >/dev/null 2>&1;
        fi
    fi
    
    echo
    echo
    echo -e "$CYAN --------------------------------------------------------------------------------------------- 	$NC"
    echo -e "$YELLOW   I am now going to open nano, please copy and paste the config from yiimp in to this file.	$NC"
    echo -e "$CYAN --------------------------------------------------------------------------------------------- 	$NC"
    echo
    read -n 1 -s -r -p "Press any key to continue"
    echo
    
    if [[ "${YIIMPCONF}" == "true" ]]; then
        sudo nano $STORAGE_ROOT/wallets/."${coind::-1}"/${coind::-1}.conf
    else
        sudo nano ${absolutepath}/wallets/."${coind::-1}"/${coind::-1}.conf
    fi
    
    clear
    cd $STORAGE_ROOT/daemon_builder
fi

clear
echo
figlet -f slant -w 100 "    DaemonBuilder" | lolcat

echo -e "$CYAN --------------------------------------------------------------------------- 	"
echo -e "$CYAN    Starting ${coind::-1} $NC"

if [[ ("$DAEMOND" == "true") ]]; then
    echo -e "$NC$GREEN    UPDATE of ${coind::-1} is completed and running. $NC"
else
    echo -e "$NC$GREEN    Installation of ${coind::-1} is completed and running. $NC"
fi

if [[ "$coindmv" == "true" ]]; then
    echo
    echo -e "$GREEN    Name of COIND :$NC $MAGENTA ${coind} $NC"
    echo -e "$GREEN    path in : $NC$YELLOW/usr/bin/${coind} $NC"
fi

if [[ "$coinclimv" == "true" ]]; then
    echo
    echo -e "$GREEN    Name of COIN-CLI :$NC $MAGENTA ${coincli} $NC"
    echo -e "$GREEN    path in : $NC$YELLOW/usr/bin/${coincli} $NC"
fi

if [[ "$cointxmv" == "true" ]]; then
    echo
    echo -e "$GREEN    Name of COIN-TX :$NC $MAGENTA ${cointx} $NC"
    echo -e "$GREEN    path in : $NC$YELLOW/usr/bin/${cointx} $NC"
fi

if [[ "$coingtestmv" == "true" ]]; then
    echo
    echo -e "$GREEN    Name of COIN-TX :$NC $MAGENTA ${coingtest} $NC"
    echo -e "$GREEN    path in : $NC$YELLOW/usr/bin/${coingtest} $NC"
fi

if [[ "$coinutilmv" == "true" ]]; then
    echo
    echo -e "$GREEN    Name of COIN-UTIL :$NC $MAGENTA ${coinutil} $NC"
    echo -e "$GREEN    path in : $NC$YELLOW/usr/bin/${coinutil} $NC"
fi

if [[ "$cointoolsmv" == "true" ]]; then
    echo
    echo -e "$GREEN    Name of COIN-TOOLS :$NC $MAGENTA ${cointools} $NC"
    echo -e "$GREEN    path in : $NC$YELLOW/usr/bin/${cointools} $NC"
fi

if [[ "$coinhashmv" == "true" ]]; then
    echo
    echo -e "$GREEN    Name of COIN-HASH :$NC $MAGENTA ${coinhash} $NC"
    echo -e "$GREEN    path in : $NC$YELLOW/usr/bin/${coinhash} $NC"
fi

if [[ "$coinwalletmv" == "true" ]]; then
    echo
    echo -e "$GREEN    Name of COIN-WALLET :$NC $MAGENTA ${coinwallet} $NC"
    echo -e "$GREEN    path in : $NC$YELLOW/usr/bin/${coinwallet} $NC"
fi

echo -e "$CYAN --------------------------------------------------------------------------- 	$NC"
echo
echo -e "$CYAN --------------------------------------------------------------------------- 	$NC"
echo -e "$GREEN    Name of Symbol coin: $NC$MAGENTA ${coin^^} 						$NC"

if [[ -f "$ADDPORTCONF" ]]; then
    echo -e "$GREEN    Algo of to Symbol ${coin^^} :$NC$MAGENTA ${COINALGO}				$NC"
    echo -e "$GREEN    Dedicated port of to Symbol ${coin^^} :$NC$MAGENTA ${COINPORT} 	$NC"
fi

echo
echo -e "$YELLOW    To use your Stratum type,$BLUE stratum.${coin,,} start|stop|restart ${coin,,} $NC"
echo -e "$YELLOW    To see the stratum screen type,$MAGENTA screen -r ${coin,,}			$NC"
echo -e "$CYAN --------------------------------------------------------------------------- 	$NC"
echo
echo -e "$CYAN --------------------------------------------------------------------------- 	$NC"
echo -e "$RED    Type$NC$MAGENTA daemonbuilder$NC$RED at anytime to install a new coin! $NC"
echo -e "$CYAN --------------------------------------------------------------------------- 	$NC"
echo

# If we made it this far everything built fine removing last coin.conf and build directory
if [[ -f "$STORAGE_ROOT/daemon_builder/temp_coin_builds/.lastcoin.conf" ]]; then
    sudo rm -f $STORAGE_ROOT/daemon_builder/temp_coin_builds/.lastcoin.conf
fi

if [[ -d "$STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}" ]]; then
    sudo rm -rf $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}
fi

if [[ -f "$STORAGE_ROOT/daemon_builder/.daemon_builder.my.cnf" ]]; then
    sudo rm -f $STORAGE_ROOT/daemon_builder/.daemon_builder.my.cnf
fi

if [[ -f "$ADDPORTCONF" ]]; then
    sudo rm -f $STORAGE_ROOT/daemon_builder/.addport.cnf
fi

clear
echo
figlet -f slant -w 100 "    DaemonBuilder" | lolcat
echo

print_header "Installation Summary"

# Display daemon status
if [[ ("$DAEMOND" == "true") ]]; then
    print_success "UPDATE of ${coind::-1} completed"
else
    print_success "Installation of ${coind::-1} completed"
fi

print_divider

# Display installed components
print_header "Installed Components"

if [[ "$coindmv" == "true" ]]; then
    print_info "Daemon       : ${MAGENTA}${coind}${NC}"
    print_info "Location     : ${YELLOW}/usr/bin/${coind}${NC}"
fi

if [[ "$coinclimv" == "true" ]]; then
    print_info "CLI Tool     : ${MAGENTA}${coincli}${NC}"
    print_info "Location     : ${YELLOW}/usr/bin/${coincli}${NC}"
fi

if [[ "$cointxmv" == "true" ]]; then
    print_info "TX Tool      : ${MAGENTA}${cointx}${NC}"
    print_info "Location     : ${YELLOW}/usr/bin/${cointx}${NC}"
fi

if [[ "$coinutilmv" == "true" ]]; then
    print_info "Utility Tool : ${MAGENTA}${coinutil}${NC}"
    print_info "Location     : ${YELLOW}/usr/bin/${coinutil}${NC}"
fi

if [[ "$coinhashmv" == "true" ]]; then
    print_info "Hash Tool    : ${MAGENTA}${coinhash}${NC}"
    print_info "Location     : ${YELLOW}/usr/bin/${coinhash}${NC}"
fi

if [[ "$coinwalletmv" == "true" ]]; then
    print_info "Wallet Tool  : ${MAGENTA}${coinwallet}${NC}"
    print_info "Location     : ${YELLOW}/usr/bin/${coinwallet}${NC}"
fi

print_divider

# Display coin configuration
print_header "Coin Configuration"
print_info "Symbol       : ${MAGENTA}${coin^^}${NC}"

if [[ -f "$ADDPORTCONF" ]]; then
    print_info "Algorithm    : ${MAGENTA}${COINALGO}${NC}"
    print_info "Port         : ${MAGENTA}${COINPORT}${NC}"
fi

print_divider

# Display stratum management commands
print_header "Stratum Management"
print_info "Start/Stop/Restart:"
echo -e "  ${BLUE}stratum.${coin,,} start|stop|restart ${coin,,}${NC}"
print_info "View Screen:"
echo -e "  ${BLUE}screen -r ${coin,,}${NC}"

print_divider

# Start the daemon
print_header "Starting Daemon"
print_status "Initializing ${coin^^} daemon..."

if [[ "$YIIMPCONF" == "true" ]]; then

    "${coind}" -datadir=$STORAGE_ROOT/wallets/."${coind::-1}" -conf="${coind::-1}".conf -daemon -shrinkdebugfile

fi

print_success "Daemon started successfully"

print_divider

# Final message
echo -e "$CYAN =========================================================================== $NC"
echo -e "$GREEN Installation process completed successfully! $NC"
echo -e "$RED Type ${MAGENTA}daemonbuilder${NC}${RED} at any time to install another coin! $NC"
echo -e "$CYAN =========================================================================== $NC"
echo

exit