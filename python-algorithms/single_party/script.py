#!/usr/bin/env python3
import json
import sys
import subprocess

def python_script_processing(params):
    task_id = params['task_id']
    algorithm_params = json.loads(params.get('algorithm_params', '{}'))
    script_content = algorithm_params.get('script_content', '')

    script_path = f'/tmp/sp_script_{task_id}.py'
    with open(script_path, 'w') as f:
        f.write(script_content)

    result = subprocess.run(['python3', script_path], capture_output=True, text=True)

    result_path = f'/opt/primihub/results/sp_script_{task_id}.txt'
    with open(result_path, 'w') as f:
        f.write(result.stdout)
        if result.stderr:
            f.write('\n--- STDERR ---\n')
            f.write(result.stderr)

    print(json.dumps({
        'status': 'success' if result.returncode == 0 else 'failed',
        'result_path': result_path,
        'exit_code': result.returncode
    }))

if __name__ == '__main__':
    params = json.loads(sys.argv[1])
    python_script_processing(params)
