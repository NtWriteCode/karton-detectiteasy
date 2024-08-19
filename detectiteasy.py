from karton.core import Karton, Task, RemoteResource
import subprocess  # nosec B404
import json


class DetectItEasy(Karton):
    identity = "karton.die"
    version = "1.0.0"
    filters = [
        {"type": "sample", "stage": "recognized"},
        {"type": "sample", "kind": "raw"},
    ]
    resource: RemoteResource | None = None

    @staticmethod
    def normalize(name: str):
        return name.lower().replace(" ", "-")

    def get_tags(self, stdout: str):
        if self.resource is None:
            return None

        try:
            parsed_data = json.loads(stdout)
        except ValueError as e:
            print(f"{str(e)}: {stdout}")
            return []

        if "detects" not in parsed_data:
            self.log.warning(
                f"{self.resource.name} failed running detect-it-easy. Error code 01"
            )
            return None

        detects = parsed_data["detects"]

        tags = set()
        for detected in detects:
            if "values" not in detected:
                continue

            for packer in detected["values"]:
                if "type" in packer and "name" in packer:
                    tag = f"die:{DetectItEasy.normalize(packer['type'])}:{DetectItEasy.normalize(packer['name'])}"
                    tags.add(tag)

        return list(tags)

    def process(self, task: Task) -> None:
        resource = task.get_resource("sample")
        if resource is None or not isinstance(resource, RemoteResource):
            return None
        else:
            self.resource = resource

        tags = None
        with self.resource.download_temporary_file() as sample_file:
            packers = subprocess.check_output(["/die/diec", "--json", sample_file.name])  # nosec B603
            tags = self.get_tags(str(packers))

        if not tags:
            return None

        tag_task = Task(
            headers={"type": "sample", "stage": "analyzed"},
            payload={"sample": self.resource, "tags": tags},
        )

        self.send_task(tag_task)


if __name__ == "__main__":
    DetectItEasy().loop()
