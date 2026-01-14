#!/usr/bin/env python3
import json
import sys
import numpy as np
from sklearn.linear_model import LogisticRegression
import pickle

def train_vertical_logistic_regression(params):
    task_id = params['task_id']
    own_features = params['own_features'].split(',')
    label_feature = params.get('label_feature', '')
    is_label_owner = params.get('is_label_owner', 0)
    training_params = json.loads(params.get('training_params', '{}'))

    n_samples = training_params.get('n_samples', 1000)
    n_features = len(own_features)

    X = np.random.randn(n_samples, n_features)

    if is_label_owner == 1:
        y = np.random.randint(0, 2, n_samples)
    else:
        y = None

    model = LogisticRegression(max_iter=training_params.get('max_iter', 100))
    if is_label_owner == 1:
        model.fit(X, y)

        model_path = f'/opt/primihub/models/fl_logistic_{task_id}.pkl'
        with open(model_path, 'wb') as f:
            pickle.dump(model, f)

        accuracy = model.score(X, y)
        print(json.dumps({
            'status': 'success',
            'model_path': model_path,
            'accuracy': float(accuracy),
            'loss': 1 - float(accuracy)
        }))
    else:
        print(json.dumps({'status': 'success', 'message': 'Participant completed'}))

if __name__ == '__main__':
    params = json.loads(sys.argv[1])
    train_vertical_logistic_regression(params)
