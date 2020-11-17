## 四川省数据处理

### 1. 准备工作

#### 1.1 拷贝文件到本地
拷贝文件到本地 (client_child.xls,client_department.xls,client_zone.xls,儿童基本情况查询.xls，接种明细查询.xls)

#### 1.2 执行文件导入 	
```
ALTER TABLE vaccination_5113244802 RENAME TO vaccination;
ALTER TABLE child_5113244802 RENAME TO child;
delete from child;
delete from vaccination;

select count(*) from child;
select count(*) from vaccination;

导入表 5113244802  5113244802
	clent_child_linshi 				导入临时个案表 (client_child.xls)
	client_zone_5113244802
	clientorgan_5113244802
	child_partn_5113244802        	儿童基本情况查询.xls
	vaccination_partn_5113244802 	接种明细查询_01.xls, 接种明细查询_02.xls 追加导入
	
	client_child_base_5113244802  	儿童基础表
	

修改 client_zone.xls 内容属性 
	划分编码：code 
	划分名称：name
	client_zone_5113244802			导入分村数据表 (client_zone.xls)
	
修改 client_department.xls 内容属性
	基本编码：	organ_Code
	全称：		organ_name
	简称：		organ_short_name
	级别：		organ_level
	上级编码：	parent_code	
	现在编码：	cur_code	
	现在编码：	select_code
	clientorgan    					导入分村数据表 (client_department.xls)
	
验证导入数量
	delete from child;
	delete from vaccination;

	select count(*) from child;
	select count(*) from vaccination;

	select count(*) from child_partn_5113244802;
	select count(*) from vaccination_partn_5113244802;
	select count(*) from clent_child_linshi;
	select count(*) from client_zone_5113244802;
	select count(*) from clientorgan_5113244802;
	
	select count(*) from client_child_base_5113244802;
```

### 2. sql文件替换
```
	select * from clent_child_linshi where 儿童姓名 like '%00%';

### 处理比较多的儿童姓名转换（50以上）
```
	create index idx_linshi_5113244802_Code on clent_child_linshi(儿童编码);
	update clent_child_linshi a, client_child_base_5113244802 b set a.儿童姓名=b.儿童姓名 WHERE a.儿童编码=b.编码 and a.儿童姓名 like '%00%';

```
### 处理比较少的儿童姓名转换
```

	-- 儿童基本情况查询 命名为 child_123
	-- 如果存在 儿童姓名不对应
	update  clent_child_linshi a ,child_partn_5113244802 b set a.儿童姓名 =b.受种者姓名 where a.儿童性别 = b.性别 and a.出生日期 = b.出生日期 and ifnull(a.父亲姓名,'') = ifnull(b.父亲姓名,'')   and ifnull(a.母亲姓名,'') = ifnull(b.母亲姓名,'') AND  儿童姓名 like '%00%';
	update  clent_child_linshi a ,child_partn_5113244802 b set a.儿童姓名 =b.受种者姓名 where a.儿童性别 = b.性别  and a.出生日期 = b.出生日期 and ifnull(a.父亲姓名,'') = ifnull(b.父亲姓名,'')     AND  儿童姓名 like '%00%';   
	update  clent_child_linshi a ,child_partn_5113244802 b set a.儿童姓名 =b.受种者姓名 where a.儿童性别 = b.性别  and a.出生日期 = b.出生日期 and ifnull(a.母亲姓名,'') = ifnull(b.母亲姓名,'')      AND  儿童姓名 like '%00%';

	
```


	-- 【节点操作1】 
	drop table if exists client_child_5113244802;
	create table client_child_5113244802 as select * from client_child_tmp where 1=2;
	insert into client_child_5113244802  select * from clent_child_linshi;
	drop table clent_child_linshi;

	-- 【节点操作2】 创建导入临时表
	drop table if exists import_data_5113244802;
	create table import_data_5113244802 as select * from import_data where 1=2;
	insert into import_data_5113244802 select 受种者姓名,性别,出生日期,身份证号,疫苗大类,接种疫苗,接种属性,剂次,接种年度,接种年月,接种日期,接种地点,录入单位,
	 录入时间,录入人,批号,生产企业,免费,接种部位,接种途径,登记医生,接种护士,接种标记,父亲姓名,母亲姓名,区域划分,户籍属性,学校名称,职业,在册情况,
	 家庭电话,手机号码,通讯地址,幼儿园,监管码,APP标志,效期,接种剂量,规格 from vaccination_partn_5113244802;

	-- 【节点操作3】 第一步执行
	drop table if exists import_data_5113244802_step1;
	create table import_data_5113244802_step1 as select * from import_data_5113244802;
	ALTER TABLE import_data_5113244802_step1 ADD (Code VARCHAR(20));
	ALTER TABLE import_data_5113244802_step1 ADD (PK_ALL VARCHAR(500));
	ALTER TABLE import_data_5113244802_step1 ADD (PK_ALL_MD5 VARCHAR(100));
	create index idx_data_5113244802_Code on import_data_5113244802_step1(Code);
	create index idx_data_5113244802_pK_MD5 on import_data_5113244802_step1(PK_ALL_MD5);
	-- 分村编码更新
	update import_data_5113244802_step1 a set live_town = (select code from client_zone_5113244802 b where a.live_town=b.name) where a.live_town in (select name from client_zone_5113244802); 
	-- 替换左右空格
	update import_data_5113244802_step1 set PK_ALL=concat(ifnull(trim(name),''),'_',ifnull(trim(gender),''),'_',ifnull(trim(birth_date),''),'_',ifnull(trim(mother_name),''),'_',ifnull(trim(father_name),''),'_',ifnull(trim(live_town),''),'_',ifnull(trim(REPLACE(REPLACE(live_address, CHAR(10), ''), CHAR(13),'')),''));
	update import_data_5113244802_step1 set PK_ALL_md5=MD5(PK_ALL);

	-- 【节点操作4】 处理个案
	drop table if exists client_child_5113244802_step1;
	create table client_child_5113244802_step1 as select  * from client_child_5113244802;
	ALTER TABLE client_child_5113244802_step1 ADD (vacc_count VARCHAR(10));
	ALTER TABLE client_child_5113244802_step1 ADD (PK_ALL VARCHAR(500));
	ALTER TABLE client_child_5113244802_step1 ADD (PK_ALL_CHILD VARCHAR(500));
	ALTER TABLE client_child_5113244802_step1 ADD (PK_ALL_MD5 VARCHAR(100));
	ALTER TABLE client_child_5113244802_step1 ADD (PK_ALL_CHILD_MD5 VARCHAR(100));
	create index idx_yuan_5113244802_code on client_child_5113244802_step1(code);
	create index idx_data_5113244802_pK_MD5 on client_child_5113244802_step1(PK_ALL_MD5);
	create index idx_data_5113244802_CH_pK_MD5 on client_child_5113244802_step1(PK_ALL_CHILD_MD5);
	
	update client_child_5113244802_step1 set name = '' where name = '(null)';
	update client_child_5113244802_step1 set mother_name = '' where mother_name = '(null)';
	update client_child_5113244802_step1 set father_name = '' where father_name = '(null)';
	update client_child_5113244802_step1 set live_address = '' where live_address = '(null)';
	update client_child_5113244802_step1 set tongxun_address = '' where tongxun_address = '(null)';

	update client_child_5113244802_step1 set PK_ALL=concat(ifnull(trim(name),''),'_',ifnull(trim(gender),''),'_',ifnull(trim(birth_date),''),'_',ifnull(trim(mother_name),''),'_',ifnull(trim(father_name),''),'_',ifnull(trim(live_town),''),'_',ifnull(trim(REPLACE(REPLACE(live_address, CHAR(10), ''), CHAR(13),'')),''));
	update client_child_5113244802_step1 set PK_ALL_child=concat(ifnull(trim(name),''),'_',ifnull(trim(gender),''),'_',ifnull(trim(birth_date),''),'_',ifnull(trim(mother_name),''),'_',ifnull(trim(father_name),''),'_',ifnull(trim(live_town),''),'_',ifnull(trim(REPLACE(REPLACE(tongxun_address, CHAR(10), ''), CHAR(13),'')),''));
	update client_child_5113244802_step1 set PK_ALL_MD5=MD5(PK_ALL);
	update client_child_5113244802_step1 set PK_ALL_CHILD_MD5=MD5(PK_ALL_child);

	
	-- 数据重复的
	-- 1.排除状态 record_status != 'D' 
	INSERT INTO repeat_child_step1
	SELECT * FROM client_child_5113244802_step1 WHERE code IN
	(
		SELECT code code2 FROM(
			SELECT * FROM client_child_5113244802_step1 WHERE PK_ALL_MD5 IN (
					SELECT PK_ALL_MD5 FROM client_child_5113244802_step1 group by PK_ALL_MD5 having count(*)>1
			) AND code NOT IN (
					SELECT max(code) FROM client_child_5113244802_step1 group by PK_ALL_MD5 having count(*)>1
			) AND code NOT IN(
					SELECT code code1 FROM client_child_5113244802_step1 WHERE PK_ALL_MD5 IN (
						SELECT PK_ALL_MD5 FROM client_child_5113244802_step1 group by PK_ALL_MD5 having count(*)>1
					) AND record_status !='D'
			)
		) a
	);
	DELETE FROM client_child_5113244802_step1 WHERE code IN(
		SELECT code code2 FROM(
			SELECT * FROM client_child_5113244802_step1 WHERE PK_ALL_MD5 IN (
					SELECT PK_ALL_MD5 FROM client_child_5113244802_step1 group by PK_ALL_MD5 having count(*)>1
			) AND code NOT IN (
					SELECT max(code) FROM client_child_5113244802_step1 group by PK_ALL_MD5 having count(*)>1
			) AND code NOT IN(
					SELECT code code1 FROM client_child_5113244802_step1 WHERE PK_ALL_MD5 IN (
						SELECT PK_ALL_MD5 FROM client_child_5113244802_step1 group by PK_ALL_MD5 having count(*)>1
					) AND record_status !='D'
			)
		) a
	);
	-- 2.排除code 最大的
	INSERT INTO repeat_child_step1
	SELECT * FROM client_child_5113244802_step1 WHERE code IN
	(
		SELECT code code1 FROM(
			SELECT * FROM client_child_5113244802_step1 WHERE PK_ALL_MD5 IN (
					SELECT PK_ALL_MD5 FROM client_child_5113244802_step1 group by PK_ALL_MD5 having count(*)>1
			) AND code NOT IN (
					SELECT max(code) FROM client_child_5113244802_step1 group by PK_ALL_MD5 having count(*)>1
			)
		) a
	);
	DELETE FROM client_child_5113244802_step1 WHERE code IN(
		SELECT code code1 FROM(
			SELECT * FROM client_child_5113244802_step1 WHERE PK_ALL_MD5 IN (
					SELECT PK_ALL_MD5 FROM client_child_5113244802_step1 group by PK_ALL_MD5 having count(*)>1
			) AND code NOT IN (
					SELECT max(code) FROM client_child_5113244802_step1 group by PK_ALL_MD5 having count(*)>1
			)
		) a
	);
	
	-- 是否存在重复个案
	select PK_ALL_MD5,count(*) from client_child_5113244802_step1 group by PK_ALL_MD5 having count(*)>1;
	-- create table repead_client_child select * from client_child_5113244802_step1 where 1=2
	-- insert into repead_client_child select * from client_child_5113244802_step1 where PK_ALL_MD5 = '52cb56a7151ec645d4938be5a3be3be2' and code = '511324480220209346';
	-- delete from client_child_5113244802_step1 where code = '***替换***20209346';
	-- select * from repead_client_child where code = '***替换***20209346';
	-- 处理重复个案 （没有则创建）
	-- create table repead_client_child select * from client_child_5113244802_step1 where 1=2


	-- 执行第二步
	update import_data_5113244802_step1 a set code = (select code from client_child_5113244802_step1 b where a.PK_ALL_MD5=b.PK_ALL_MD5);
	-- update import_data_5113244802_step1 a,client_child_5113244802_step1 b set a.code = b.code where a.PK_ALL_MD5=b.PK_ALL_MD5;
	-- update import_data_5113244802_step1 a join client_child_5113244802_step1 b on a.PK_ALL_MD5=b.PK_ALL_MD5 set a.code = b.code;
	 -- 查询如果是0条标识全部处理完了
	 -- 如果大于0：
	 --         表示 client_child_5113244802_step1 和 import_data_5113244802_step1 多个信息结合不匹配
	 --			可能设计到的表有 1. client_child_5113244802 2.import_data_5113244802
	 --			如果修改了表 client_child_5113244802 需要回到 【节点操作4】
	 --			如果修改了表 import_data_5113244802 需要回到 【节点操作3】
	select count(*) from import_data_5113244802_step1 where code is   null;




	-- 【节点操作5】 执行第三步
	drop table if exists import_base_5113244802;
	create table import_base_5113244802 as select * from import_base where 1=2;
	insert into import_base_5113244802 select 受种者姓名,性别,出生年度,出生年月,出生日期,父亲姓名,母亲姓名,手机号码,家庭电话,通讯地址,在册情况,区域划分,
	身份证号,出生证号,户籍属性,户口属性,建卡日期,父亲电话,母亲电话,父亲手机,母亲手机,父亲身份证,母亲身份证,家庭住址,户口地址,入园年度,幼儿园,现管理单位,原管理单位,备注,APP标志,出生医院,公众号 from child_partn_5113244802;

	-- 【节点操作6】 
	drop table if exists import_base_5113244802_step1;
	create table import_base_5113244802_step1 as select * from import_base_5113244802;
	update import_base_5113244802_step1 a set live_town = (select code from client_zone_5113244802 b where a.live_town=b.name) where a.live_town in (select name from client_zone_5113244802); 

	ALTER TABLE import_base_5113244802_step1 ADD (code VARCHAR(20));
	ALTER TABLE import_base_5113244802_step1 ADD (PK_ALL VARCHAR(500));
	create index idx_base_5113244802_code on import_base_5113244802_step1(code);
	ALTER TABLE import_base_5113244802_step1 ADD (PK_ALL_MD5 VARCHAR(100));
	create index import_base_5113244802_step1 on client_child_5113244802_step1(PK_ALL_MD5);

	update import_base_5113244802_step1 set PK_ALL=concat(ifnull(trim(name),''),'_',ifnull(trim(gender),''),'_',ifnull(trim(birth_date),''),'_',ifnull(trim(mother_name),''),'_',ifnull(trim(father_name),''),'_',ifnull(trim(live_town),''),'_',ifnull(trim(REPLACE(REPLACE(live_address, CHAR(10), ''), CHAR(13),'')),''));
	update import_base_5113244802_step1 set PK_ALL_MD5=MD5(PK_ALL);
	update import_base_5113244802_step1 a set code = (select code from client_child_5113244802_step1 b where a.PK_ALL_MD5=b.PK_ALL_CHILD_MD5);

	--  select b.code, count(*) from import_base_5113244802_step1 a,client_child_5113244802_step1 b where a.PK_ALL_MD5=b.PK_ALL_CHILD_MD5 GROUP BY b.code HAVING count(*)>1

	-- 如果存在code is null,原因是client_child_5113244802_step1 做了去重，导致去重的数据在import_base_5113244802_step1没有找到
	select * from import_base_5113244802_step1 where code is null;
	-- select * from client_child_5113244802_step1 where mother_name = '(null)'
	-- update client_child_5113244802_step1 set mother_name = '' where mother_name = '(null)'

	-- 如果存在重复输数据
	-- delete from import_base_5113244802_step1 where code is null;
	-- 插入重复记录
	-- insert into repead_child_import_base select * from import_base_5113244802_step1 where code is null;
	-- delete from import_base_5113244802_step1 where code is null;

	-- 【节点操作7】 执行第四步
	drop table if exists child_5113244802;
	create table child_5113244802 as select * from child where 1=2;
	create index idx_child_5113244802_code on child_5113244802(code); 
	insert into child_5113244802(code ,name,gender,birth_date,father_name,mother_name,famil_mobile,famil_phone,live_address,record_type,live_town,t_id_card,birth_card,huji_type,t_hukou,t_jianka_date,t_father_phone,t_mother_phone,t_father_mobile,t_mother_mobile,t_father_idCard,t_mother_idCard,t_family_address,t_hukou_address,t_kinder_year,t_kinder_id,t_cur_organ,t_old_organ,t_remark,app_mark,t_birth_hosptal,t_wechat) select code ,name,gender,birth_date,father_name,mother_name,famil_mobile,famil_phone,live_address,record_type,live_town,t_id_card,birth_card,huji_type,t_hukou,t_jianka_date,t_father_phone,t_mother_phone,t_father_mobile,t_mother_mobile,t_father_idCard,t_mother_idCard,t_family_address,t_hukou_address,t_kinder_year,t_kinder_id,t_cur_organ,t_old_organ,t_remark,app_mark,t_birth_hosptal,t_wechat 
	from import_base_5113244802_step1;

	drop table if exists vaccination_5113244802;
	create table vaccination_5113244802 as select * from vaccination where 1=2;

	-- code 不能为空
	-- select code,vaccine_name from import_data_5113244802_step1 where code is null;
	-- DELETE from import_data_5113244802_step1 where code is null;

	insert into vaccination_5113244802(code,vaccine_name,vaccine_small_name,vaccine_proptity,vaccine_seq,vaccine_date,vaccine_organ_Id,input_organ,input_time,inputer,batch_number,smanufactor,free_mark,vacc_part,vacc_tujing,vacc_doctor,vacc_nurse,vacc_biaoji,piats,validate_date,jiliang,guige,ID) 
	select code,vaccine_name,vaccine_small_name,vaccine_proptity ,vaccine_seq,vaccine_date,vaccine_area_Id,input_organ,input_time,inputer,batch_number,smanufactor,free_mark,vacc_part,vacc_tujing,vacc_doctor,vacc_nurse,vacc_biaoji,piats,validate_date,jiliang,guige,MD5(concat(code,IFNULL(vaccine_small_name,''),IFNULL(vaccine_proptity,''),IFNULL(vaccine_seq,''),IFNULL(vaccine_date,''),unix_timestamp(now()),CEILING(RAND()*900+100)))  from import_data_5113244802_step1;

	-- 更新个案信息
	update child_5113244802 a set record_type = (select record_status from client_child_5113244802_step1 b where a.code=b.code);
	update child_5113244802 a set huji_type = (select huji from client_child_5113244802_step1 b where a.code=b.code);
	update child_5113244802 a set t_hukou = (select hukou from client_child_5113244802_step1 b where a.code=b.code);
	update child_5113244802 a set race = (select race from client_child_5113244802_step1 b where a.code=b.code);
	update child_5113244802 a set t_cur_organ = (select cur_organ from client_child_5113244802_step1 b where a.code=b.code);
	update child_5113244802 a set t_old_organ = (select old_organ from client_child_5113244802_step1 b where a.code=b.code);
	update child_5113244802 a set cardNo = (select cardNo from client_child_5113244802_step1 b where a.code=b.code);
	update child_5113244802 a set createOrgan = (select createOrgan from client_child_5113244802_step1 b where a.code=b.code);
	update child_5113244802 a set createPerson = (select createPerson from client_child_5113244802_step1 b where a.code=b.code);
	update child_5113244802 a set healthno = (select healthno from client_child_5113244802_step1 b where a.code=b.code);
	update child_5113244802 a set birthWight = (select birthWight from client_child_5113244802_step1 b where a.code=b.code);
	update child_5113244802 a set parity = (select parity from client_child_5113244802_step1 b where a.code=b.code);
	update child_5113244802 a set habiId = (select habiId from client_child_5113244802_step1 b where a.code=b.code);
	update child_5113244802 a set motherhb = (select motherhb from client_child_5113244802_step1 b where a.code=b.code);
	update child_5113244802 a set lastUpdateTime = (select lastUpdateTime from client_child_5113244802_step1 b where a.code=b.code);
	update child_5113244802 a set recordDate = (select recordDate from client_child_5113244802_step1 b where a.code=b.code);
	update child_5113244802 set syncStatus='2';

	select * from child_5113244802;
	select * from vaccination_5113244802;
``` 

### 3. 修改数据
```
-- 检查是否重复数据
select count(*) from child_5113244802;
select count(*) from vaccination_5113244802;
select id,count(*) from vaccination_5113244802 group by id having count(*)>1

-- 重复数据插入保存
insert into  repead_child  select * from child_5113244802 where code  in (select code from child )  and t_cur_organ='5113244802';
insert into  repead_vacccination  select * from vaccination_5113244802 where code in (select code from repead_child);

-- 删除重复个案
delete from child_5113244802 where code in (select code from repead_child);
-- 删除重复接种信息
delete from vaccination_5113244802 where code in (select code from repead_child);

create index idx_cur_code_5113244802 on child_5113244802(t_cur_organ);
insert into child select * from child_5113244802 where t_cur_organ='5113244802';
insert into vaccination select * from vaccination_5113244802 where code in (select code from child_5113244802 where t_cur_organ='5113244802');

ALTER TABLE child_5113244802 RENAME TO child_5113244802_P1;
ALTER TABLE child RENAME TO child_5113244802;
ALTER TABLE vaccination_5113244802 RENAME TO vaccination_5113244802_P1;
ALTER TABLE vaccination RENAME TO vaccination_5113244802;

-- 倒完后执行
ALTER TABLE vaccination_5113244802 RENAME TO vaccination;
ALTER TABLE child_5113244802 RENAME TO child;
```

### 4. 处理个案重复异常
```
RENAME TABLE clientorgan TO clientorgan_5113244802;


	-- 是否存在重复个案
	-- 添加自增长主键，处理重复
	alter table child_5113244802 add id int not null auto_increment primary key; 
	-- 删除重复
	DELETE FROM child_5113244802 WHERE id IN(
		SELECT id id1 FROM(
			SELECT * FROM child_5113244802 WHERE code IN (
				SELECT code FROM child_5113244802 group by code having count(*)>1
			) AND id NOT IN (
				SELECT max(id) FROM child_5113244802 group by code having count(*)>1
			)
		) a
	);
	-- 删除自增长主键
	alter table child_5113244802 drop column id;
	
	
```	

### 处理儿童基本信息重复
```

	drop table if exists clent_child_5113244802_tmp;
	create table clent_child_5113244802_tmp SELECT * from child_partn_5113244802;
	
	SELECT count(*) FROM clent_child_5113244802_tmp;
	
	drop table if exists child_partn_5113244802;
	create table child_partn_5113244802 SELECT DISTINCT* from clent_child_5113244802_tmp;
	
```



SELECT t_cur_organ, COUNT(t_cur_organ) from  child_5113244802_P1 GROUP BY t_cur_organ order by COUNT(t_cur_organ) desc

	select * from clent_child_linshi where 儿童姓名 like '%00%';


SELECT * from  child_partn_5113244802 WHERE 出生日期 = '2012-06-22'

SELECT * from clent_child_linshi WHERE `儿童编码` = '510922050120120213'

UPDATE clent_child_linshi set 儿童姓名 = '王辅晨'
