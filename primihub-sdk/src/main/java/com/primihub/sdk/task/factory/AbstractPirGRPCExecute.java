package com.primihub.sdk.task.factory;

import com.google.protobuf.ByteString;
import com.primihub.sdk.task.cache.CacheService;
import com.primihub.sdk.task.param.TaskPIRParam;
import com.primihub.sdk.task.param.TaskParam;
import io.grpc.Channel;
import java_worker.PushTaskReply;
import java_worker.PushTaskRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import primihub.rpc.Common;

import java.nio.charset.StandardCharsets;

public class AbstractPirGRPCExecute extends AbstractGRPCExecuteFactory {

    private final static String QUERY_CONFIG_JSON = "{ \"SERVER\": {\"key_columns\": <key_columns>, \"label_columns\": <label_columns>} }";

    private final static Logger log = LoggerFactory.getLogger(AbstractPirGRPCExecute.class);

    private CacheService cacheService;

    @Override
    public CacheService getCacheService() {
        return cacheService;
    }

    @Override
    public void setCacheService(CacheService cacheService) {
        this.cacheService = cacheService;
    }

    @Override
    public void execute(Channel channel, TaskParam taskParam) {
        runPir(channel,taskParam);
    }

    private void runPir(Channel channel, TaskParam<TaskPIRParam> param){
        try {
            log.info("grpc run {} - time:{}", param.toString(), System.currentTimeMillis());
            Common.Params.Builder paramsBuilder = Common.Params.newBuilder();
            Common.ParamValue serverDataParamValue = Common.ParamValue.newBuilder().setValueString(ByteString.copyFrom(param.getTaskContentParam().getServerData().getBytes(StandardCharsets.UTF_8))).build();
            Common.ParamValue pirTagParamValue = Common.ParamValue.newBuilder().setValueInt32(param.getTaskContentParam().getPirType()).build();
            Common.ParamValue outputFullFilenameParamValue = Common.ParamValue.newBuilder().setValueString(ByteString.copyFrom(param.getTaskContentParam().getOutputFullFilename().getBytes(StandardCharsets.UTF_8))).build();
            paramsBuilder.putParamMap("serverData", serverDataParamValue);
            paramsBuilder.putParamMap("pirType", pirTagParamValue);
            paramsBuilder.putParamMap("outputFullFilename", outputFullFilenameParamValue);

            if (param.getTaskContentParam().getPirType() == 0) {
                // ID_PIR: use queryIndeies (range format "start:count")
                String joined = String.join(",", param.getTaskContentParam().getQueryParam());
                Common.ParamValue queryIndeiesParamValue = Common.ParamValue.newBuilder()
                    .setValueString(ByteString.copyFrom(joined.getBytes(StandardCharsets.UTF_8)))
                    .build();
                paramsBuilder.putParamMap("queryIndeies", queryIndeiesParamValue);
                // ID_PIR also needs QueryConfig for label columns
                String queryConfig = QUERY_CONFIG_JSON
                    .replace("<key_columns>", param.getTaskContentParam().getKeyColumnsString() != null ?
                        param.getTaskContentParam().getKeyColumnsString() : "[]")
                    .replace("<label_columns>", param.getTaskContentParam().getLabelColumnsString() != null ?
                        param.getTaskContentParam().getLabelColumnsString() : "[]");
                Common.ParamValue aueryConfigParamValue = Common.ParamValue.newBuilder().setValueString(ByteString.copyFrom(queryConfig.getBytes(StandardCharsets.UTF_8))).build();
                paramsBuilder.putParamMap("QueryConfig", aueryConfigParamValue);
            } else {
                // KEY_PIR: use clientData + QueryConfig
                Common.string_array.Builder builder = Common.string_array.newBuilder();
                for (String str : param.getTaskContentParam().getQueryParam()) {
                    builder.addValueStringArray(ByteString.copyFrom(str.getBytes(StandardCharsets.UTF_8)));
                }
                Common.ParamValue clientDataParamValue = Common.ParamValue.newBuilder().setIsArray(true).setValueStringArray(builder).build();
                paramsBuilder.putParamMap("clientData", clientDataParamValue);

                String queryConfig = "";
                if (param.getTaskContentParam().getKeyColumns() == null || param.getTaskContentParam().getKeyColumns().length==0){
                    param.setError("KeyColumns 不可以为空");
                    param.setSuccess(false);
                    param.setEnd(true);
                    log.info("grpc end {} - time:{}", param.toString(), System.currentTimeMillis());
                    return;
                }
                queryConfig = QUERY_CONFIG_JSON
                    .replace("<key_columns>", param.getTaskContentParam().getKeyColumnsString())
                    .replace("<label_columns>", param.getTaskContentParam().getLabelColumnsString());
                Common.ParamValue aueryConfigParamValue = Common.ParamValue.newBuilder().setValueString(ByteString.copyFrom(queryConfig.getBytes(StandardCharsets.UTF_8))).build();
                paramsBuilder.putParamMap("QueryConfig", aueryConfigParamValue);
            }
            Common.TaskContext taskBuild = assembleTaskContext(param);
            Common.Task task = Common.Task.newBuilder()
                    .setType(Common.TaskType.PIR_TASK)
                    .setParams(paramsBuilder.build())
                    .setName("pirTask")
                    .setTaskInfo(taskBuild)
                    .setLanguage(Common.Language.PROTO)
                    .setCode(ByteString.copyFrom("".getBytes(StandardCharsets.UTF_8)))
                    .putPartyDatasets("SERVER", Common.Dataset.newBuilder().putData("SERVER", param.getTaskContentParam().getServerData()).build())
                    .build();
            log.info("grpc Common.Task :\n{}",task.toString());
            PushTaskRequest request = PushTaskRequest.newBuilder()
                    .setIntendedWorkerId(ByteString.copyFrom("1".getBytes(StandardCharsets.UTF_8)))
                    .setTask(task)
                    .setSequenceNumber(11)
                    .setClientProcessedUpTo(22)
                    .build();
            PushTaskReply reply = runVMNodeGrpc(o -> o.submitTask(request),channel);
            log.info("grpc result:"+reply);
            if (reply.getRetCode()==0){
                param.setPartyCount(reply.getPartyCount());
                if (param.getOpenGetStatus()){
                    continuouslyObtainTaskStatus(channel,taskBuild,param,reply.getPartyCount());
                }
            }else {
                param.setError(reply.getMsgInfo().toStringUtf8());
                param.setSuccess(false);
            }
            log.info("grpc end {} - time:{}", param.toString(), System.currentTimeMillis());
        } catch (Exception e) {
            param.setSuccess(false);
            param.setError(e.getMessage());
            log.info("grpc pir Exception:{}",e.getMessage());
            e.printStackTrace();
        }
        param.setEnd(true);
    }
}
