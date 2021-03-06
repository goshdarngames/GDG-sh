# Command to send a source file to the web-assembly build server,
# and perform unit testing with 'Unity'

#Username@Hostname for the server used to build webassembly
build_server="boop@web-asm"

#Path to find the Unity testing framework repo on build server
unity_path="~/Unity/"

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
	printf "and uses Unity to perform unit testing.\n"
	printf "\n"
	printf "It is expected that the c file being tested will have\n"
	printf "corresponding .h and .test.c files.\n"
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

#derive the test filename from the source filename
test_path=$(echo $source_path | sed "s/c$/test.c/g")
test_file=$(basename $test_path)

# debug
#echo "$test_path"

#derive the header filename from the source filename
header_path=$(echo $source_path | sed "s/c$/h/g")

# debug
#echo "$header_path"

#create build dir 
ssh $build_server "mkdir -p $build_path"

#copy source file to the build dir on the build server
scp $source_path $build_server:$build_path

#copy test file
scp $test_path $build_server:$build_path

#copy header file
scp $header_path $build_server:$build_path

#copy unity files to the test dir
ssh $build_server "cp $unity_path/src/unity* $build_path"

#generate test runner
ssh $build_server "cd $build_path && 
	               ruby $unity_path/auto/generate_test_runner.rb \
                   $test_file test-runner.c"

#build test with gcc
ssh $build_server "cd $build_path && gcc *.c -o Test"

#run test
ssh $build_server "cd $build_path && ./Test"

#remove the build folder on build server
ssh $build_server "rm -rf $build_path"
