# Command to send a source file to the web-assembly build server,
# and perform unit testing with 'Check'

#Username@Hostname for the server used to build webassembly
build_server="boop@web-asm"

#directory to perform the build on the build server
build_path="/tmp/c-unit-test"

#command + otions to perform the build
build_cmd="$emcc -O3 -s WASM=1 -s EXTRA_EXPORTED_RUNTIME_METHODS='[\"cwrap\"]'"

display_usage ()
{
	printf "\n"
	printf "c-unit-test.sh [source_file]\n"
	printf "\n"
	printf "Sends the sourcefile to the web-asm build server \n"
	printf "and uses Check to perform unit testing.\n"
	printf "\n"
}

if [ $# -lt 1 ]
then
	display_usage
	exit 1
fi

#Full path and filename of the source file
source_path=$(readlink -m -n $1)
source_file=$(basename $source_path)

#create build dir 
ssh $build_server "mkdir -p $build_path"

#copy source file to the build dir on the build server
scp $source_path $build_server:$build_path

#execute the build command
ssh $build_server "cd $build_path && $build_cmd $source_file"

#copy the output files to current dir on local machine
scp $build_server:$build_path/a.out.* .

#remove the build folder on build server
ssh $build_server "rm -rf $build_path"
