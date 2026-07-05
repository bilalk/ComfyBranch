from huggingface_hub import list_repo_files

repos = [
    "Kijai/WanVideo_comfy",
    "Comfy-Org/Wan_2.1_ComfyUI_repackaged",
    "Wan-AI/Wan2.1-T2V-1.3B",
]

for repo in repos:
    print("===", repo, "===")
    try:
        files = list_repo_files(repo, repo_type="model")
        for item in files[:250]:
            print(item)
        print("COUNT", len(files))
    except Exception as exc:
        print("ERR", exc)