package com.primihub.biz.repository.primarydb.data;

import com.primihub.biz.entity.data.po.DataUnion;
import com.primihub.biz.entity.data.po.DataUnionTask;
import org.springframework.stereotype.Repository;

@Repository
public interface DataUnionPrRepository {

    void saveDataUnion(DataUnion dataUnion);

    void saveDataUnionTask(DataUnionTask task);

    void updateDataUnionTask(DataUnionTask task);

    void updateDataUnion(DataUnion dataUnion);

    void delUnionTask(Long taskId);

    void delUnion(Long unionId);
}
