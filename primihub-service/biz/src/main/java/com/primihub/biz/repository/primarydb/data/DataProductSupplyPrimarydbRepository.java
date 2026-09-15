package com.primihub.biz.repository.primarydb.data;

import com.primihub.biz.entity.data.po.DataProductSupply;
import org.apache.ibatis.annotations.Param;

import java.util.List;
import java.util.Map;

/**
 * 数据产品供给Repository接口
 */
public interface DataProductSupplyPrimarydbRepository {

    /**
     * 插入数据产品供给
     */
    int insertDataProductSupply(DataProductSupply supply);

    /**
     * 更新数据产品供给
     */
    int updateDataProductSupply(DataProductSupply supply);

    /**
     * 删除数据产品供给
     */
    int deleteDataProductSupply(@Param("id") Long id);

    /**
     * 根据ID查询数据产品供给
     */
    DataProductSupply selectDataProductSupplyById(@Param("id") Long id);

    /**
     * 查询数据产品供给列表
     */
    List<DataProductSupply> selectDataProductSupplyList(Map<String, Object> params);

    /**
     * 查询数据产品供给总数
     */
    int selectDataProductSupplyCount(Map<String, Object> params);

    /**
     * 根据机构ID查询
     */
    List<DataProductSupply> selectDataProductSupplyByOrganId(@Param("organId") Long organId);

    /**
     * 根据节点ID查询
     */
    List<DataProductSupply> selectDataProductSupplyByNodeId(@Param("nodeId") Long nodeId);

    /**
     * 批量插入
     */
    int batchInsertDataProductSupply(@Param("list") List<DataProductSupply> list);
}
