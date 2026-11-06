import re

with open('E:/QUANTA_VLSI/success_test_1/success_test_1.xpr', 'r', encoding='utf-8') as f:
    text = f.read()

runs_match = re.search(r'<Runs Version="1" Minor="22">(.*?)</Runs>', text, re.DOTALL)
if runs_match:
    runs = runs_match.group(1)
    for run in re.finditer(r'<Run Id="(synth_1|impl_1|vlsi_design_cnn_top_0_0_synth_1)"(.*?)</Run>', runs, re.DOTALL):
        print(f"=== RUN {run.group(1)} ===")
        print(run.group(2)[:1500])

