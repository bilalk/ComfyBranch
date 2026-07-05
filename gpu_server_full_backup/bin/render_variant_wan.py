#!/usr/bin/env python3
from pathlib import Path
p=Path('/mnt/gpu-work/models/wan')
print('Wan model files:', sum(1 for _ in p.rglob('*') if _.is_file()) if p.exists() else 0)
print('Wan variant runner placeholder: Wan I2V workflow requires selected model and VRAM validation.')
