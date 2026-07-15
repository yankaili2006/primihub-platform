package com.primihub.application.controller.sys;
import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.sys.param.TriggerSyncParam;
import com.primihub.biz.service.sys.SysDataExchangeLogService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
@RequestMapping("dataExchange")
@RestController
public class DataExchangeLogController {
    @Autowired private SysDataExchangeLogService service;
    @RequestMapping("getList") public BaseResultEntity getList() { return service.getList(); }
    @RequestMapping("triggerSync") public BaseResultEntity triggerSync(TriggerSyncParam param) {
        if (param.getExchangeName()==null||"".equals(param.getExchangeName().trim()))
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM,"exchangeName");
        return service.triggerSync(param);
    }
    @RequestMapping("delete") public BaseResultEntity delete(Long id) {
        if (id==null) return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM,"id");
        return service.delete(id);
    }
}