package com.primihub.biz.service.data.analysis;

import com.primihub.biz.entity.data.vo.FunctionDefVO;
import com.primihub.biz.entity.data.vo.SqlValidateVO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

@Slf4j
@Component
public class SQLRewriteEngine {

    private static final Pattern SQL_INJECTION_PATTERN = Pattern.compile(
        "('\\s*OR\\s*1\\s*=\\s*1|;\\s*DROP\\s+|;\\s*DELETE\\s+|;\\s*UPDATE\\s+|;\\s*INSERT\\s+|EXEC\\s+|EXECUTE\\s+|\\.\\./)",
        Pattern.CASE_INSENSITIVE);

    private static final Pattern TABLE_PATTERN = Pattern.compile(
        "\\bFROM\\s+(\\w+)|\\bJOIN\\s+(\\w+)", Pattern.CASE_INSENSITIVE);

    private static final Pattern COLUMN_PATTERN = Pattern.compile(
        "\\bSELECT\\s+(.+?)\\bFROM", Pattern.CASE_INSENSITIVE | Pattern.DOTALL);

    public SqlValidateVO validate(String sql, String dataResources) {
        SqlValidateVO vo = new SqlValidateVO();
        List<String> suggestions = new ArrayList<>();

        if (sql == null || sql.trim().isEmpty()) {
            vo.setValid(false);
            vo.setMessage("SQL不能为空");
            return vo;
        }

        Matcher injectionMatcher = SQL_INJECTION_PATTERN.matcher(sql);
        if (injectionMatcher.find()) {
            vo.setValid(false);
            vo.setMessage("SQL包含潜在注入风险");
            vo.setSuggestions(suggestions);
            return vo;
        }

        List<String> tables = new ArrayList<>();
        Matcher tableMatcher = TABLE_PATTERN.matcher(sql);
        while (tableMatcher.find()) {
            String table = tableMatcher.group(1) != null ? tableMatcher.group(1) : tableMatcher.group(2);
            if (table != null) tables.add(table.toUpperCase());
        }
        vo.setTables(tables.stream().distinct().collect(Collectors.toList()));

        Matcher columnMatcher = COLUMN_PATTERN.matcher(sql);
        if (columnMatcher.find()) {
            String cols = columnMatcher.group(1).trim();
            List<String> columns = Arrays.stream(cols.split(","))
                .map(c -> c.trim().replaceAll("\\s+AS\\s+\\w+", ""))
                .map(c -> c.replaceAll(".*\\.", ""))
                .filter(c -> !c.equals("*"))
                .collect(Collectors.toList());
            vo.setColumns(columns);
        }

        vo.setPrivacyFields(new ArrayList<>());
        if (sql.toUpperCase().contains("JOIN")) {
            suggestions.add("检测到跨表JOIN，将使用PSI求交替代");
        }
        if (sql.toUpperCase().contains("GROUP BY")) {
            suggestions.add("GROUP BY操作将在各节点本地执行后合并结果");
        }
        if (sql.contains("DELETE") || sql.contains("INSERT") || sql.contains("UPDATE")) {
            vo.setValid(false);
            vo.setMessage("仅支持SELECT查询");
            return vo;
        }

        vo.setValid(true);
        vo.setMessage("校验通过");
        vo.setSuggestions(suggestions);
        return vo;
    }

    public String format(String sql) {
        if (sql == null || sql.isEmpty()) return "";
        String result = sql.trim()
            .replaceAll("(?i)\\bSELECT\\b", "\nSELECT\n  ")
            .replaceAll("(?i)\\bFROM\\b", "\nFROM\n  ")
            .replaceAll("(?i)\\bWHERE\\b", "\nWHERE\n  ")
            .replaceAll("(?i)\\bAND\\b", "\n  AND")
            .replaceAll("(?i)\\bOR\\b", "\n  OR")
            .replaceAll("(?i)\\bJOIN\\b", "\nJOIN\n  ")
            .replaceAll("(?i)\\bON\\b", "\n  ON")
            .replaceAll("(?i)\\bGROUP\\s+BY\\b", "\nGROUP BY\n  ")
            .replaceAll("(?i)\\bORDER\\s+BY\\b", "\nORDER BY\n  ")
            .replaceAll("(?i)\\bHAVING\\b", "\nHAVING\n  ")
            .replaceAll("(?i)\\bLIMIT\\b", "\nLIMIT")
            .replaceAll(",\\s*(?=\\S)", ",\n  ");
        return result.trim();
    }

    public String rewrite(String sql, List<String> crossNodeTables) {
        String rewritten = sql;
        if (crossNodeTables != null && !crossNodeTables.isEmpty()) {
            for (String table : crossNodeTables) {
                rewritten = rewritten.replaceAll("(?i)\\b" + Pattern.quote(table) + "\\b",
                    table + "_local");
            }
        }
        return rewritten;
    }

    public List<FunctionDefVO> getFunctions(String category) {
        List<FunctionDefVO> result = new ArrayList<>();
        if (category == null || category.equals("string")) {
            result.addAll(stringFunctions());
        }
        if (category == null || category.equals("datetime")) {
            result.addAll(datetimeFunctions());
        }
        if (category == null || category.equals("numeric")) {
            result.addAll(numericFunctions());
        }
        return result;
    }

    private List<FunctionDefVO> stringFunctions() {
        return Arrays.asList(
            def("string", "CONCAT", "字符串拼接", "CONCAT(a, b)"),
            def("string", "SUBSTRING", "字符串截取", "SUBSTRING(s, 1, 3)"),
            def("string", "LENGTH", "字符串长度", "LENGTH(s)"),
            def("string", "UPPER", "转大写", "UPPER(s)"),
            def("string", "LOWER", "转小写", "LOWER(s)"),
            def("string", "TRIM", "去除空格", "TRIM(s)"),
            def("string", "REPLACE", "字符串替换", "REPLACE(s, 'a', 'b')")
        );
    }

    private List<FunctionDefVO> datetimeFunctions() {
        return Arrays.asList(
            def("datetime", "NOW", "当前时间", "NOW()"),
            def("datetime", "DATE", "提取日期", "DATE(datetime)"),
            def("datetime", "YEAR", "提取年份", "YEAR(date)"),
            def("datetime", "MONTH", "提取月份", "MONTH(date)"),
            def("datetime", "DAY", "提取日", "DAY(date)"),
            def("datetime", "DATE_ADD", "日期加法", "DATE_ADD(date, INTERVAL 1 DAY)")
        );
    }

    private List<FunctionDefVO> numericFunctions() {
        return Arrays.asList(
            def("numeric", "ABS", "绝对值", "ABS(x)"),
            def("numeric", "ROUND", "四舍五入", "ROUND(x, 2)"),
            def("numeric", "CEILING", "向上取整", "CEILING(x)"),
            def("numeric", "FLOOR", "向下取整", "FLOOR(x)"),
            def("numeric", "POWER", "幂运算", "POWER(x, y)"),
            def("numeric", "SQRT", "平方根", "SQRT(x)")
        );
    }

    private FunctionDefVO def(String category, String name, String desc, String example) {
        FunctionDefVO vo = new FunctionDefVO();
        vo.setCategory(category);
        vo.setName(name);
        vo.setDescription(desc);
        vo.setExample(example);
        return vo;
    }
}
