package com.primihub.biz.task;

import com.primihub.biz.repository.primarydb.sys.WhitelistPrimarydbRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.text.SimpleDateFormat;
import java.util.Calendar;

/**
 * 白名单日志清理定时任务
 */
@Slf4j
@Component
public class WhitelistLogCleanTask {

    @Autowired
    private WhitelistPrimarydbRepository whitelistPrimarydbRepository;

    /**
     * 每天凌晨2点执行清理任务
     * 清理30天前的日志
     */
    @Scheduled(cron = "0 0 2 * * ?")
    public void cleanExpiredLogs() {
        try {
            log.info("开始执行白名单访问日志清理任务");

            // 清理30天前的日志
            int days = 30;
            SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
            Calendar calendar = Calendar.getInstance();
            calendar.add(Calendar.DAY_OF_MONTH, -days);
            String beforeDate = sdf.format(calendar.getTime());

            int count = whitelistPrimarydbRepository.deleteExpiredLogs(beforeDate);

            log.info("白名单访问日志清理任务执行完成，清理{}天前的日志，共删除{}条记录", days, count);
        } catch (Exception e) {
            log.error("白名单访问日志清理任务执行失败", e);
        }
    }

    /**
     * 每小时执行一次统计任务
     * 用于缓存统计数据或触发告警
     */
    @Scheduled(cron = "0 0 * * * ?")
    public void hourlyStatistics() {
        try {
            log.debug("执行白名单访问日志每小时统计任务");

            // 可以在这里添加统计逻辑，比如：
            // 1. 统计异常访问次数
            // 2. 检查是否有频繁失败的IP
            // 3. 触发告警通知等

        } catch (Exception e) {
            log.error("白名单访问日志统计任务执行失败", e);
        }
    }
}
