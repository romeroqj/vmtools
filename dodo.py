def task_build_image():
    return {
        "actions": [
            "cd alpine && "
            "rm -rf output-alpine && "
            "packer build -force template.pkr.hcl"
        ]
    }


def upload_image():
    ...
