# Bye bye demo
# USE WITH CAUTION!

kubectl delete --all zk
kubectl delete --all znode
kubectl delete --all kafka
kubectl delete --all superset
kubectl delete --all supersetdb
kubectl delete --all druidconnections.superset.stackable.tech
kubectl delete --all druid
kubectl delete --all trino
kubectl delete --all hbase
kubectl delete --all hdfs
kubectl delete --all hive
kubectl delete --all nifi
kubectl delete --all opa
kubectl delete --all airflow
kubectl delete --all airflowdb
kubectl delete --all sparkapplication

kubectl delete --all job

helm ls -a | tail -n +2 | awk '{print $1;}' | grep -v '.*-operator' | xargs helm un

kubectl delete --all pvc
