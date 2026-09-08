package com.primihub.biz.repository.primarydb.data;

import com.primihub.biz.entity.data.po.DataModelArtifact;
import org.springframework.stereotype.Repository;

@Repository
public interface DataModelArtifactPrRepository {

    void saveModelArtifact(DataModelArtifact artifact);

    void updateModelArtifact(DataModelArtifact artifact);

    void deleteModelArtifact(Long artifactId);
}
