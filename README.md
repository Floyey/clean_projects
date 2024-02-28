# Project Cleanup Script

This Bash script is designed to clean up all projects by removing non-essential directories and files. It helps keep your projects neat and organized by automatically eliminating any unnecessary items.

## Functionality

The script accepts several arguments to specify the base path of the projects, directories, and file patterns to delete, along with an option to execute the cleanup automatically without additional confirmation.

### Arguments

- `-b` **Base path**: The base path where the projects to be cleaned are located. (required)
- `-d` **Directory to delete**: Specifies one or multiple directories to delete. Can be used multiple times to specify more than one directory. (optional)
- `-f` **File pattern to delete**: Specifies one or multiple file patterns to delete. Use this option multiple times to specify more than one pattern. (optional)
- `-y` **Clean all projects automatically**: Executes the cleanup of all projects automatically without asking for confirmation. (optional)
- `-h, --help`: Displays the help message and exits.

## Usage

To use the script, you must at least provide the base path with `-b` and specify a directory or file pattern to delete with `-d` or `-f`. The `-y` option is useful for automating the process without manual intervention.

Example command:

```bash
./script.sh -b /path/to/projects -d vendor -d node_modules -f *.log -y
```

## Demo

![Script Demo](https://i.imgur.com/prJin1c.gif)

This GIF demonstrates the script in action, showing how it cleans up non-essential directories and files from projects automatically.

## Contributing

Contributions are welcome! If you have ideas for improvements or have found a bug, please feel free to submit a pull request or open an issue.
