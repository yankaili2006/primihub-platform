#!/usr/bin/env python3
import json
import sys
import numpy as np
import pandas as pd
from sklearn.linear_model import LogisticRegression
import pickle

def lr_algorithm(params):
    task_id = params['task_id']
    selected_features = params.get('selected_features', '').split(',')
    algorithm_params = json.loads(params.get('algorithm_params', '{}'))

    n_samples = 1000
    X = np.random.randn(n_samples, len([f for f in selected_features if f]))
    y = np.random.randint(0, 2, n_samples)

    model = LogisticRegression(max_iter=algorithm_params.get('max_iter', 100))
    model.fit(X, y)

    model_path = f'/opt/primihub/models/sp_lr_{task_id}.pkl'
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
    lr_algorithm(params)
