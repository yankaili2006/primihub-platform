#!/usr/bin/env python3
import json
import sys
import numpy as np
import pandas as pd
try:
    import xgboost as xgb
except ImportError:
    from sklearn.ensemble import GradientBoostingClassifier as xgb
import pickle

def xgboost_algorithm(params):
    task_id = params['task_id']
    selected_features = params.get('selected_features', '').split(',')
    algorithm_params = json.loads(params.get('algorithm_params', '{}'))

    n_samples = 1000
    X = np.random.randn(n_samples, len([f for f in selected_features if f]))
    y = np.random.randint(0, 2, n_samples)

    try:
        model = xgb.XGBClassifier(
            n_estimators=algorithm_params.get('n_estimators', 100),
            max_depth=algorithm_params.get('max_depth', 3)
        )
    except:
        model = xgb(
            n_estimators=algorithm_params.get('n_estimators', 100),
            max_depth=algorithm_params.get('max_depth', 3)
        )

    model.fit(X, y)

    model_path = f'/opt/primihub/models/sp_xgboost_{task_id}.pkl'
    with open(model_path, 'wb') as f:
        pickle.dump(model, f)

    accuracy = model.score(X, y)

    print(json.dumps({
        'status': 'success',
        'model_path': model_path,
        'accuracy': float(accuracy)
    }))

if __name__ == '__main__':
    params = json.loads(sys.argv[1])
    xgboost_algorithm(params)
