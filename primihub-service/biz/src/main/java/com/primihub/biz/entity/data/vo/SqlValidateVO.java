package com.primihub.biz.entity.data.vo;

import lombok.Data;
import java.util.List;

@Data
public class SqlValidateVO {
    private Boolean valid;
    private List<String> tables;
    private List<String> columns;
    private List<String> privacyFields;
    private List<String> suggestions;
    private String message;
}
