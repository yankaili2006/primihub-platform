{
	"roles": {
	  "server": "Alice",
	  "client": [
		"Bob",
		"Charlie"
	  ]
	},
	"common_params": {
	  "model": "HFL_CNN",
	  "method": "${encryption!"Plaintext"}",
	  "process": "train",
	  "task_name": "HFL_CNN",
<#if (encryption!"Plaintext") == "DPSGD">
	  "delta": ${delta!0.0001},
	  "l2_norm_clip": ${maxGradNorm!1.0},
	  "noise_multiplier": ${noiseMultiplier!2.0},
</#if>
	  "learning_rate": ${learningRate!0.01},
	  "alpha": ${alpha!0.0001},
	  "optimizer": "${optimizer!"adam"}",
	  "batch_size": ${batchSize!100},
	  "global_epoch": ${globalEpoch!10},
	  "local_epoch": ${localEpoch!1},
	  "print_metrics": ${printMetrics!true?c}
	},
	"role_params": {
	  "Bob": {
		"data_set": "${label_dataset}",
		"model_path": "${hostModelFileName}",
		"metric_path": "${indicatorFileName}"
	  },
	  "Charlie": {
		"data_set": "${guest_dataset}",
		"model_path": "${guestModelFileName}",
		"metric_path": "${indicatorFileName}"
	  },
	  "Alice": {
		"data_set": "${arbiter_dataset}",
		"metric_path": "/data${indicatorFileName}"
	  }
	}
}
