package com.primihub.biz.repository.primarydb.sys;

import com.primihub.biz.entity.sys.po.MonitorAlertConfig;
import com.primihub.biz.entity.sys.po.MonitorAlertHistory;
import com.primihub.biz.entity.sys.po.MonitorRecord;
import org.apache.ibatis.annotations.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

@Repository
public interface MonitorPrimarydbRepository {

    // ========== 告警配置 ==========

    void insertAlertConfig(MonitorAlertConfig config);

    void updateAlertConfig(MonitorAlertConfig config);

    void deleteAlertConfig(@Param("id") Long id);

    MonitorAlertConfig selectAlertConfigById(@Param("id") Long id);

    List<MonitorAlertConfig> selectAlertConfigList(Map<String, Object> params);

    int selectAlertConfigCount(Map<String, Object> params);

    List<MonitorAlertConfig> selectEnabledAlertConfigs();

    // ========== 告警历史 ==========

    void insertAlertHistory(MonitorAlertHistory history);

    void updateAlertHistory(MonitorAlertHistory history);

    MonitorAlertHistory selectAlertHistoryById(@Param("id") Long id);

    List<MonitorAlertHistory> selectAlertHistoryList(Map<String, Object> params);

    int selectAlertHistoryCount(Map<String, Object> params);

    int selectTodayAlertCount();

    int selectPendingAlertCount();

    // ========== 监控记录 ==========

    void insertMonitorRecord(MonitorRecord record);

    void batchInsertMonitorRecord(List<MonitorRecord> records);

    MonitorRecord selectLatestMonitorRecord(@Param("monitorType") String monitorType, @Param("metricName") String metricName);

    List<MonitorRecord> selectMonitorRecordList(Map<String, Object> params);

    int selectMonitorRecordCount(Map<String, Object> params);

    List<MonitorRecord> selectMonitorHistory(@Param("monitorType") String monitorType,
                                              @Param("startTime") String startTime,
                                              @Param("endTime") String endTime);
}
