#!/usr/bin/env python3
import json
import sys
import numpy as np
import pandas as pd

def data_statistics(params):
    task_id = params['task_id']
    selected_features = params.get('selected_features', '').split(',')

    n_samples = 1000
    data = {feat: np.random.randn(n_samples) for feat in selected_features if feat}
    df = pd.DataFrame(data)

    stats = df.describe().to_dict()

    result_path = f'/opt/primihub/results/sp_statistics_{task_id}.json'
    with open(result_path, 'w') as f:
        json.dump(stats, f, indent=2)

    print(json.dumps({
        'status': 'success',
        'result_path': result_path,
        'result_rows': len(df)
    }))

if __name__ == '__main__':
    params = json.loads(sys.argv[1])
    data_statistics(params)
