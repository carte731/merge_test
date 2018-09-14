#!/bin/bash

set -e
set -u

#   Arguments
setup_routine=$1 # Which routine are we running
SOURCE=$2 # Where is ANGSD-wrapper?

#	Download and install SAMTools 1.3
function installSAMTools() {
#	wget https://github.com/samtools/samtools/releases/download/1.3/samtools-1.3.tar.bz2 # Download SAMTools
#	tar -xvjf samtools-1.3.tar.bz2 # Extract the tarball
#	rm -f samtools-1.3.tar.bz2 # Get rid of the tarball
#	cd samtools-1.3 # Change into the SAMTools directory
#	./configure --prefix=$(pwd) # Configure the installation process, setting the install directory to be here
#	make # Compile the code
#	make install # Install SAMTools
#	echo "export PATH=$(pwd):"'${PATH}' >> ~/.bash_profile # Add the path to bash_profile

        wget https://github.com/samtools/samtools/releases/download/1.8/samtools-1.8.tar.bz2 # Download SAMTools
        tar -xvjf samtools-1.8.tar.bz2 # Extract the tarball
        rm -f samtools-1.8.tar.bz2 # Get rid of the tarball
        cd samtools-1.8 # Change into the SAMTools directory
        ./configure --with-htslib=${HTSLIB_DIR} --prefix=$(pwd) # Configure the installation process, setting the install directory to be here
#	./configure --enable-configure-htslib CPPFLAGS='-I "${xzPath}"/include' LDFLAGS='-L ${xzPath}"/lib' --prefix=$(pwd -P)
        make # Compile the code
        make install # Install SAMTools
        echo "export PATH=$(pwd):"'${PATH}' >> ~/.bash_profile # Add the path to bash_profile
#	echo "export LD_LIBRARY_PATH=$(pwd):"'${LD_LIBRARY_PATH}' >> ~/.bash_profile # Add the path to bash_profile
}

#   Export the function
export -f installSAMTools

case "${setup_routine}" in
    "dependencies" )
        #   Check to see if Git and Wget are installed
        if ! $(command -v git > /dev/null 2> /dev/null); then echo "Please install Git and place in your PATH" >&2 ; exit 1; fi
        if ! $(command -v wget > /dev/null 2> /dev/null); then echo "Please install Wget and place in your PATH" >&2 ; exit 1; fi
        #   Let angsd-wrapper be run from anywhere
        echo alias "angsd-wrapper='`pwd -P`/angsd-wrapper'" >> ~/.bash_profile
        #   Make the 'dependencies' directory
        cd "${SOURCE}"
        mkdir dependencies
        cd dependencies
        ROOT=$(pwd)
        #   Check for SAMTools. If not found, install it
#        if ! $(command -v samtools > /dev/null 2> /dev/null); then cd "${ROOT}"; installSAMTools; source ~/.bash_profile;cd "${ROOT}"; fi
        #   Install ngsF
        cd "${ROOT}"
        git clone https://github.com/fgvieira/ngsF.git
        cd ngsF
#        git reset --hard 807ca7216ab8c3fbd98e628ef1638177d5c752b9
	git reset --hard d980b85c0746c297285e2e415193914aa0d0412a ## ngsF 1.2.0
        make
        cd "${ROOT}"
	## INSTALLING XZ UTIL
##	wget https://tukaani.org/xz/xz-5.2.4.tar.gz
#	wget https://github.com/xz-mirror/xz/releases/download/v5.2.2/xz-5.2.2.tar.gz
#	cp ~/xz-5.2.4.tar.gz xz-5.2.4.tar.gz
#	tar -xvf xz-5.2.4.tar.gz
#	tar -xvf xz-5.2.2.tar.gz
#	git clone https://github.com/xz-mirror/xz.git
#	git reset --hard 9815cdf6987ef91a85493bfcfd1ce2aaf3b47a0a
#	rm xz-5.2.4.tar.gz
#	rm xz-5.2.2.tar.gz
#	cd xz-5.2.2
#	cd xz-5.2.4
#	cd xz
#	git reset --hard 9815cdf6987ef91a85493bfcfd1ce2aaf3b47a0a
#	./autogen.sh
#	./configure --prefix=$(pwd -P)
#	make
#	make install
#	xzPath=$(pwd -P)
#	echo -e "\n$xzPath\n"	
        #   Install HTSLIB
        cd "${ROOT}"
#        git clone https://github.com/samtools/htslib.git
	wget https://github.com/samtools/htslib/releases/download/1.8/htslib-1.8.tar.bz2
	tar -xvf htslib-1.8.tar.bz2
	rm htslib-1.8.tar.bz2
#        cd htslib
	cd htslib-1.8
#        git reset --hard bb03b0287bc587c3cbdc399f49f0498eef86b44a
#	git reset --hard 209f94ba28d62a566c77e3fbf034e3ee76807815
#        autoheader
#	autoconf
##	autoreconf
	./configure --prefix=$(pwd -P)
#	echo -e "\n$xzPath/include\n"
#	./configure CPPFLAGS=" -I ${xzPath}/include" LDFLAGS=" -L ${xzPath}/lib" --prefix=$(pwd -P)
	make
#        make prefix=`pwd` install
	make install
#	export LD_LIBRARY_PATH=${xzPath}/lib
        # if [ -z "${LD_LIBRARY_PATH}" ]; then
        #         LD_LIBRARY_PATH="${xzPath}/lib"
        #         echo "export $LD_LIBRARY_PATH" >> ~/.bash_profile
        # else
        #         echo "export LD_LIBRARY_PATH=${xzPath}/lib:"'${LD_LIBRARY_PATH}' >> ~/.bash_profile
        # fi
        # export LD_LIBRARY_PATH="${xzPath}/lib"${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
#	echo "export LD_LIBRARY_PATH=${xzPath}/lib:"'${LD_LIBRARY_PATH}' >> ~/.bash_profile
#	echo "export LD_LIBRARY_PATH=${xzPath}/lib:"'${LD_LIBRARY_PATH}' >> ~/.bashrc
#        echo "export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${xzPath}/lib" >> ~/.bash_profile
        HTSLIB_DIR=$(pwd -P)
        cd "${ROOT}"
        #   Install ANGSD
        if ! $(command -v samtools > /dev/null 2> /dev/null); then cd "${ROOT}"; installSAMTools; source ~/.bash_profile;cd "${ROOT}"; fi
        cd "${ROOT}"
#        git clone https://github.com/ANGSD/angsd.git
	wget http://popgen.dk/software/download/angsd/angsd0.920.tar.gz
	tar -xvf angsd0.920.tar.gz
	rm angsd0.920.tar.gz
        cd angsd
#        git reset --hard 1c0ebb672c25c6e6a53db66c61519e970e48c72e
## updates to angsd 0.921
	echo -e "\nMAKING ANGSD 0.921\n"
        make HTSSRC="${HTSLIB_DIR}" 
	cd "${ROOT}"
        #   Install ngsAdmix
        cd "${ROOT}"
        mkdir ngsAdmix
        cd ngsAdmix
        wget http://popgen.dk/software/download/NGSadmix/ngsadmix32.cpp
        g++ ngsadmix32.cpp -O3 -lpthread -lz -o NGSadmix
        cd "${ROOT}"
        #   Install ngsPopGen
        cd "${ROOT}"
        git clone https://github.com/mfumagalli/ngsPopGen.git
        cd ngsPopGen
#        git reset --hard bbd73d5caa660f28111c69eefca3230ded4a97ac
        git reset --hard 8ead2d469f42942f413f6c93664b568d2eb8a124
	make
        cd "${ROOT}"
        echo
        #   Display final setup message
        echo "Please run 'source ~/.bash_profile' to complete installation"
        ;;
    "data" )
        #   Check for depenent programs
        if ! $(command -v wget > /dev/null 2> /dev/null); then echo "Please install Wget and place in your PATH" >&2 ; exit 1; fi
        if ! $(command -v samtools > /dev/null 2> /dev/null); then echo "Please install SAMTools and place in your PATH" >&2; exit 1; fi
        #   Download and set up the test data
        if [[ ${SOURCE} == '.' ]]; then SOURCE=$(pwd -P); fi
        cd "${SOURCE}"
        if [[ -d "Example_Data" ]]; then rm -rf Example_Data/; fi # Remove any old example datasets
        wget --no-check-certificate --output-document=Example_Data.tar.bz2 https://ndownloader.figshare.com/files/5282197
        tar -xvjf Example_Data.tar.bz2
        rm Example_Data.tar.bz2
        EXAMPLE_DIR="${SOURCE}/Example_Data"
        #       Change into the example data directory
        cd "${EXAMPLE_DIR}"
        #       Create lists of sample names
        echo "Creating sample lists..." >&2
        find "${EXAMPLE_DIR}"/Maize/ -name "*.bam" | sort > Maize/Maize_Samples.txt
        find "${EXAMPLE_DIR}"/Mexicana -name "*.bam" | sort > Mexicana/Mexicana_Samples.txt
        find "${EXAMPLE_DIR}"/Teosinte -name "*.bam" | sort > Teosinte/Teosinte_Samples.txt
        #   Make sure all inbreeding files are named "*.indF"
        for inbreeding in $(find ${EXAMPLE_DIR} -name "*Inbreeding.txt")
        do
            BASE=$(basename ${inbreeding} | cut -f 1 -d '.')
            DIR=$(dirname ${inbreeding})
            mv ${inbreeding} ${DIR}/${BASE}.indF
        done
        #       Index the reference and ancestral sequences
        echo "Indexing reference and ancestral sequences..." >&2
        cd Sequences
        find "${EXAMPLE_DIR}" -name "*.fa" -exec samtools faidx {} \;
        #   Index the BAM files
        echo "Indexing the BAM files..." >&2
        cd "${EXAMPLE_DIR}"/Maize # Maize samples
        for i in $(cat Maize_Samples.txt); do samtools index "$i"; done
        cd "${EXAMPLE_DIR}"/Mexicana # Mexicana samples
        for i in $(cat Mexicana_Samples.txt); do samtools index "$i"; done
        cd "${EXAMPLE_DIR}"/Teosinte # Teosinte samples
        for i in $(cat Teosinte_Samples.txt); do samtools index "$i"; done
        cd "${EXAMPLE_DIR}"
        #   Write the example configuration files
        echo "Writing example configuration files..." >&2
        source "${SOURCE}/Wrappers/writeConfigs.sh"
        CONFIG_DIR=$(writeConfigs ${EXAMPLE_DIR})
        #   Finished
        echo
        echo "Test data can be found at ${EXAMPLE_DIR}"
        echo "Example configuration files can be found at ${CONFIG_DIR}"
        ;;
esac
