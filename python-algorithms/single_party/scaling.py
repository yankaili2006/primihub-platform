#!/usr/bin/env python3
import json
import sys
import numpy as np
import pandas as pd
from sklearn.preprocessing import StandardScaler

def data_scaling(params):
    task_id = params['task_id']
    selected_features = params.get('selected_features', '').split(',')

    n_samples = 1000
    data = {feat: np.random.randn(n_samples) for feat in selected_features if feat}
    df = pd.DataFrame(data)

    scaler = StandardScaler()
    df_scaled = pd.DataFrame(scaler.fit_transform(df), columns=df.columns)

    result_path = f'/opt/primihub/results/sp_scaling_{task_id}.csv'
    df_scaled.to_csv(result_path, index=False)

    print(json.dumps({
        'status': 'success',
        'result_path': result_path,
        'result_rows': len(df_scaled)
    }))

if __name__ == '__main__':
    params = json.loads(sys.argv[1])
    data_scaling(params)
