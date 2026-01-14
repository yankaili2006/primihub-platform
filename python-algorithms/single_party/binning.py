#!/usr/bin/env python3
import json
import sys
import numpy as np
import pandas as pd

def feature_binning(params):
    task_id = params['task_id']
    selected_features = params.get('selected_features', '').split(',')
    algorithm_params = json.loads(params.get('algorithm_params', '{}'))
    n_bins = algorithm_params.get('n_bins', 5)

    n_samples = 1000
    data = {feat: np.random.randn(n_samples) for feat in selected_features if feat}
    df = pd.DataFrame(data)

    for col in df.columns:
        df[col + '_binned'] = pd.cut(df[col], bins=n_bins, labels=False)

    result_path = f'/opt/primihub/results/sp_binning_{task_id}.csv'
    df.to_csv(result_path, index=False)

    print(json.dumps({
        'status': 'success',
        'result_path': result_path,
        'result_rows': len(df)
    }))

if __name__ == '__main__':
    params = json.loads(sys.argv[1])
    feature_binning(params)
