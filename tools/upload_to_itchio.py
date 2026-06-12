butler_cli = "butler"
build_directory = "build/web"
user_name = "ozelotvanilla"
project_name = "minute-minuet"
channel_name = "web"

if __name__ == "__main__":
    command_to_run = f"{butler_cli} push {build_directory} {user_name}/{project_name}:{channel_name}"

    print(f"Will run:\n`{command_to_run}`\nEnter `y` to continue, or anything else to cancel: ", end="")
    if input().lower() == "y":
        import subprocess
        subprocess.run(command_to_run, shell=True)
    else:
        print("Upload cancelled.")
