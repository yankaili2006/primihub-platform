#!/usr/bin/env python3
import json
import sys
import numpy as np
import pickle

def predict_vertical_xgboost(params):
    task_id = params['task_id']
    model_id = params['model_id']
    own_features = params['own_features'].split(',')

    model_path = f'/opt/primihub/models/fl_xgboost_{model_id}.pkl'
    with open(model_path, 'rb') as f:
        model = pickle.load(f)

    n_samples = 100
    X = np.random.randn(n_samples, len(own_features))

    predictions = model.predict(X)
    try:
        probabilities = model.predict_proba(X)
        result_data = np.column_stack([predictions, probabilities])
    except:
        result_data = predictions.reshape(-1, 1)

    result_path = f'/opt/primihub/results/fl_xgboost_pred_{task_id}.csv'
    np.savetxt(result_path, result_data, delimiter=',')

    print(json.dumps({
        'status': 'success',
        'result_path': result_path,
        'result_rows': n_samples
    }))

if __name__ == '__main__':
    params = json.loads(sys.argv[1])
    predict_vertical_xgboost(params)
