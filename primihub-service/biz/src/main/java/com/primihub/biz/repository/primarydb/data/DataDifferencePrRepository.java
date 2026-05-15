package com.primihub.biz.repository.primarydb.data;

import com.primihub.biz.entity.data.po.DataDifference;
import com.primihub.biz.entity.data.po.DataDifferenceTask;
import org.springframework.stereotype.Repository;

@Repository
public interface DataDifferencePrRepository {

    void saveDataDifference(DataDifference dataDifference);

    void saveDataDifferenceTask(DataDifferenceTask task);

    void updateDataDifferenceTask(DataDifferenceTask task);

    void updateDataDifference(DataDifference dataDifference);

    void delDifferenceTask(Long taskId);

    void delDifference(Long differenceId);
}
