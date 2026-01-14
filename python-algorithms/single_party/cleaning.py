#!/usr/bin/env python3
import json
import sys
import numpy as np
import pandas as pd

def data_cleaning(params):
    task_id = params['task_id']
    selected_features = params.get('selected_features', '').split(',')

    n_samples = 1000
    data = {feat: np.random.randn(n_samples) for feat in selected_features if feat}
    df = pd.DataFrame(data)

    df = df.dropna()
    df = df.drop_duplicates()

    result_path = f'/opt/primihub/results/sp_cleaning_{task_id}.csv'
    df.to_csv(result_path, index=False)

    print(json.dumps({
        'status': 'success',
        'result_path': result_path,
        'result_rows': len(df)
    }))

if __name__ == '__main__':
    params = json.loads(sys.argv[1])
    data_cleaning(params)
