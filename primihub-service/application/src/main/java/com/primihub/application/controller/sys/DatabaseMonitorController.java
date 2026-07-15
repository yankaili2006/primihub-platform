package com.primihub.application.controller.sys;
import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.sys.param.SaveDatabaseMonitorParam;
import com.primihub.biz.service.sys.SysDatabaseMonitorService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
@RequestMapping("databaseMonitor")
@RestController
public class DatabaseMonitorController {
    @Autowired private SysDatabaseMonitorService service;
    @RequestMapping("getList") public BaseResultEntity getList() { return service.getList(); }
    @RequestMapping("save") public BaseResultEntity save(SaveDatabaseMonitorParam param) {
        if (param.getDbType()==null||"".equals(param.getDbType().trim()))
            return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM,"dbType");
        return service.save(param);
    }
    @RequestMapping("delete") public BaseResultEntity delete(Long id) {
        if (id==null) return BaseResultEntity.failure(BaseResultEnum.LACK_OF_PARAM,"id");
        return service.delete(id);
    }
}