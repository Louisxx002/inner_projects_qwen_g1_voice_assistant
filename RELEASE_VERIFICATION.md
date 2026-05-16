# Release Verification

Verified on 2026-05-16 from a clean release copy.

Checks passed:

- `scripts/check_project.sh`
- `scripts/check_full_pipeline.sh`
- `GET /health` returned `ok: true`
- `GET /infer?text=小g 你叫什么名字` returned a Qwen reply
- Edge TTS generated `runtime/tts.mp3`
- `ffmpeg` converted the TTS output to 16 kHz mono PCM WAV
- Unitree SDK2 Python imports resolved from bundled `third_party/unitree_sdk2_python`

Runtime files, logs, bytecode caches, and generated audio are intentionally excluded from the repository.
