#!/usr/bin/env python3
import json
import sys
import numpy as np
import pandas as pd
from sklearn.feature_selection import SelectKBest, f_classif

def feature_selection(params):
    task_id = params['task_id']
    selected_features = params.get('selected_features', '').split(',')
    algorithm_params = json.loads(params.get('algorithm_params', '{}'))
    k = algorithm_params.get('k', 5)

    n_samples = 1000
    data = {feat: np.random.randn(n_samples) for feat in selected_features if feat}
    df = pd.DataFrame(data)
    y = np.random.randint(0, 2, n_samples)

    selector = SelectKBest(f_classif, k=min(k, len(df.columns)))
    df_selected = pd.DataFrame(selector.fit_transform(df, y))

    result_path = f'/opt/primihub/results/sp_selection_{task_id}.csv'
    df_selected.to_csv(result_path, index=False)

    print(json.dumps({
        'status': 'success',
        'result_path': result_path,
        'result_rows': len(df_selected)
    }))

if __name__ == '__main__':
    params = json.loads(sys.argv[1])
    feature_selection(params)
