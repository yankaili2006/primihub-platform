package com.primihub.application.controller.sys;
import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.sys.param.SaveMonitorConfigParam;
import com.primihub.biz.service.sys.SysOsMonitorConfigService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
@RequestMapping("monitorConfig")
@RestController
public class MonitorConfigController {
    @Autowired private SysOsMonitorConfigService service;
    @RequestMapping("getList") public BaseResultEntity getList() { return service.getList(); }
    @RequestMapping("save") public BaseResultEntity save(SaveMonitorConfigParam param) {
        if (param.getConfigKey()==null||"".equals(param.getConfigKey().trim()))
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM,"configKey");
        return service.save(param);
    }
    @RequestMapping("delete") public BaseResultEntity delete(Long id) {
        if (id==null) return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM,"id");
        return service.delete(id);
    }
}