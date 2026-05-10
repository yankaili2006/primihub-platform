package com.primihub.biz.entity.sys.vo;

import lombok.Data;

@Data
public class LoginRestrictionVO {
    private Boolean forceChangePassword;
    private Integer passwordMinLength;
    private Boolean passwordRequireUpper;
    private Boolean passwordRequireLower;
    private Boolean passwordRequireDigit;
    private Boolean passwordRequireSpecial;
    private Integer maxLoginAttempts;
    private Integer lockDurationMinutes;
    private Integer lockResetMinutes;
    private Boolean captchaEnabled;
    private Integer sessionTimeoutMinutes;
}
