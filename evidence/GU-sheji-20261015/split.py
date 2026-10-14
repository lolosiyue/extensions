import json, os
SRC="/workspace/finaldebug-md-ascii/sheji.md"; OFF=38  # local line n -> file line 38+n
L=open(SRC,encoding="utf-8").read().split("\n")
hdr={"sj2":(1,1),"sj5":(32,32),"sj9":(68,68),"sj7":(105,105),"sj11":(129,129)}
E=[("sj2_yase","亚瑟·潘德拉贡","sj2",5,7),("sj2_yalishanda","亚历山大","sj2",8,10),
("sj2_dafenqi","达·芬奇","sj2",16,18),("sj2_keliaobateluo","克利奥帕特拉七世","sj2",19,21),
("sj2_beimihu","卑弥呼","sj2",22,25),
("sj5_wudawei","屋大维","sj5",36,40),("sj5_hexieede","赫西俄德","sj5",44,47),
("sj5_danduoluo","恩里克·丹多洛","sj5",48,50),("sj5_duer","穆罕默德·杜尔","sj5",51,53),
("sj5_nuochadanmasi","诺查丹玛斯","sj5",54,56),("sj5_gongbenwuzang","宫本武藏","sj5",57,59),
("sj5_maladuona","马拉多纳","sj5",60,63),("sj5_beiduofen","贝多芬","sj5",64,66),
("sj9_caoxiu","曹休","sj9",72,73),("sj9_xizhicai","戏志才","sj9",74,76),("sj9_luoxian","罗宪","sj9",77,78),
("sj9_qinmi","秦宓","sj9",79,81),("sj9_chengpu","程普","sj9",82,83),("sj9_hansui","韩遂","sj9",87,89),
("sj9_liuyan","刘焉","sj9",90,92),("sj9_fuxie","傅燮","sj9",93,95),("sj9_qiaomao","桥瑁","sj9",96,98),
("sj9_renkai","任恺","sj9",99,101),("sj9_shichong","石崇","sj9",102,103),
("sj7_dengyangdingmi","邓飏丁谧","sj7",109,111),("sj7_zhaozhi","赵直","sj7",112,114),
("sj7_ruanxian","阮咸","sj7",118,120),("sj7_liudai","刘岱","sj7",121,122),("sj7_malong","马隆","sj7",123,125),
("sj11_weiboyang","魏伯阳","sj11",133,135),("sj11_simalun","司马伦","sj11",136,138),
("sj11_maohuanghou","毛皇后","sj11",139,141),("sj11_liushao","刘劭","sj11",142,144),
("sj11_anshigao","安世高","sj11",145,147)]
def txt(a,b): return "\n".join(L[OFF+a-1:OFF+b])
batches=[]; n=4
for i in range(0,len(E),n):
    g=E[i:i+n]; bid="b%02d"%(i//n+1)
    ex=[]; names=[]; rng=[]
    for gid,cn,sec,a,b in g:
        h=hdr[sec][0]
        ex.append("%s\n(file lines %d-%d)\n%s"%(txt(h,h),OFF+a,OFF+b,txt(a,b)))
        names.append("%s\t%s\t%s"%(gid,cn,sec)); rng.append([OFF+a,OFF+b])
    d=".staging/"+bid; os.makedirs(d,exist_ok=True)
    open(d+"/excerpts.md","w",encoding="utf-8").write("\n\n---\n\n".join(ex)+"\n")
    open(d+"/names.md","w",encoding="utf-8").write("general_id\tname\tsection\n"+"\n".join(names)+"\n")
    batches.append({"id":bid,"generals":[x[0] for x in g],"names":[x[1] for x in g],"line_ranges":rng})
json.dump(batches,open("evidence/GU-sheji-20261015/batches.json","w"),ensure_ascii=False,indent=1)
json.dump(batches,open(".staging/batches.json","w"),ensure_ascii=False,indent=1)
print(len(batches),"batches",len(E),"generals")
