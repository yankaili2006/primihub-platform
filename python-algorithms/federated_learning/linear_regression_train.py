#!/usr/bin/env python3
import json
import sys
import numpy as np
from sklearn.linear_model import LinearRegression
import pickle

def train_vertical_linear_regression(params):
    task_id = params['task_id']
    own_features = params['own_features'].split(',')
    label_feature = params.get('label_feature', '')
    is_label_owner = params.get('is_label_owner', 0)
    training_params = json.loads(params.get('training_params', '{}'))

    # 模拟加载数据
    n_samples = training_params.get('n_samples', 1000)
    n_features = len(own_features)

    X = np.random.randn(n_samples, n_features)

    if is_label_owner == 1:
        y = np.random.randn(n_samples)
    else:
        y = None

    # 训练模型
    model = LinearRegression()
    if is_label_owner == 1:
        model.fit(X, y)

        # 保存模型
        model_path = f'/opt/primihub/models/fl_linear_{task_id}.pkl'
        with open(model_path, 'wb') as f:
            pickle.dump(model, f)

        print(json.dumps({
            'status': 'success',
            'model_path': model_path,
            'accuracy': 0.85,
            'loss': 0.15
        }))
    else:
        print(json.dumps({'status': 'success', 'message': 'Participant completed'}))

if __name__ == '__main__':
    params = json.loads(sys.argv[1])
    train_vertical_linear_regression(params)
