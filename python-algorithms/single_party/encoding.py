#!/usr/bin/env python3
import json
import sys
import numpy as np
import pandas as pd
from sklearn.preprocessing import LabelEncoder

def feature_encoding(params):
    task_id = params['task_id']
    selected_features = params.get('selected_features', '').split(',')

    n_samples = 1000
    data = {feat: np.random.choice(['A', 'B', 'C'], n_samples) for feat in selected_features if feat}
    df = pd.DataFrame(data)

    le = LabelEncoder()
    for col in df.columns:
        df[col] = le.fit_transform(df[col])

    result_path = f'/opt/primihub/results/sp_encoding_{task_id}.csv'
    df.to_csv(result_path, index=False)

    print(json.dumps({
        'status': 'success',
        'result_path': result_path,
        'result_rows': len(df)
    }))

if __name__ == '__main__':
    params = json.loads(sys.argv[1])
    feature_encoding(params)
