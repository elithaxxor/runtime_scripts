function scpFileTransfer() {

    scp <file to upload> <username>@<hostname>:<destination path>
    scp -r <directory to upload> <username>@<hostname>:<destination path> # dir scp
    echo "put files*.xml" | sftp -p -i ~/.ssh/key_name username@hostname.example #u using relative loc
    sftp -b batchfile.txt ~/.ssh/key_name username@hostname.example # using batch in text
}

scpFileTransfer
