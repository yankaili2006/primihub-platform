package com.primihub.biz.repository.primarydb.sys;

import com.primihub.biz.entity.sys.po.NodeCooperationCancelRecord;
import org.apache.ibatis.annotations.Param;

import java.util.List;
import java.util.Map;

/**
 * 节点取消合作历史记录Repository接口
 */
public interface NodeCooperationCancelRecordPrimarydbRepository {

    /** 插入一条取消合作记录 */
    int insertCancelRecord(NodeCooperationCancelRecord record);

    /** 分页查询取消合作记录 (params: keyword/startTime/endTime/offset/pageSize) */
    List<NodeCooperationCancelRecord> selectCancelRecordList(Map<String, Object> params);

    /** 统计取消合作记录总数 */
    int selectCancelRecordCount(Map<String, Object> params);

    /** 根据ID查询取消合作记录 */
    NodeCooperationCancelRecord selectCancelRecordById(@Param("id") Long id);
}
