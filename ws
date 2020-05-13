BASEDIR=$(dirname "$0")
api=https://saas.whitesourcesoftware.com/api/v1.1
header='Content-Type: application/json'
if [ "$userKey" == "" ]; then
  echo empty userKey
  exit 1
else
  if [ "$orgToken" == "" ]; then
    echo empty orgToken
    exit 2
  else
    data={"userKey":"$userKey","orgToken":"$orgToken","requestType":"getAllProducts"}
    pattern="\"productName\":\"$JOB_NAME\",\"productToken\":\"[0-9a-f]*\""
    curl --header "${header}" --data ${data} ${api} > wss.log
    productToken=$(cat wss.log | grep -oEi ${pattern} | cut -d ':' -f 3 | cut -d '"' -f 2)
    if [ "$productToken" == "" ]; then
      data={"userKey":"$userKey","orgToken":"$orgToken","requestType":"createProduct","productName":\"$JOB_NAME\"}
      pattern="\"productToken\":\"[0-9a-f]*\""
      curl --header "${header}" --data ${data} ${api} > wss.log
      productToken=$(cat wss.log | grep -oEi ${pattern} | cut -d ':' -f 2 | cut -d '"' -f 2)
    fi
    if [ "$productToken" == "" ]; then
      echo empty productToken
      exit 3
    else
      data={"userKey":"$userKey","orgToken":"$orgToken","requestType":"createProject","productToken":"$productToken","projectName":\"$JOB_NAME#$BUILD_NUMBER\"}
      pattern="\"projectToken\":\"[0-9a-f]*\""
      curl --header "${header}" --data ${data} ${api} > wss.log
      projectToken=$(cat wss.log | grep -oEi ${pattern} | cut -d ':' -f 2 | cut -d '"' -f 2)
      if [ "$projectToken" == "" ]; then
        echo empty projectToken
        exit 4
      else
        rm wss.log
        pattern="^\[INFO\].*Support\sToken:\s[0-9a-f]*$"
        java -Dfile.encoding=UTF-8 -jar $BASEDIR/wss-unified-agent.jar -c $BASEDIR/wss-unified-agent.config -apiKey ${orgToken} -userKey ${userKey} -projectToken ${projectToken}
        for f in `ls -t whitesource`
        do
          supportToken=$(cat whitesource/$f/whitesource.0.log | grep -oEi ${pattern} | cut -d ' ' -f 8)
          break
        done
        if [ "$supportToken" == "" ]; then
          echo empty supportToken
          exit 5
        else
          data={"userKey":"$userKey","orgToken":"$orgToken","requestType":"getRequestState","requestToken":"$supportToken"}
          pattern="\"requestState\":\"[A-Z_]*\""
          for i in 1 2 3 4 5 6 7 8 9
          do
            state=$(curl --header "${header}" --data ${data} ${api} | grep -oEi ${pattern} | cut -d ':' -f 2 | cut -d '"' -f 2)
            sleep `expr $i \* 10`
            echo state:$state
            if [ "$state" == "FINISHED" ]; then
              data={"userKey":"$userKey","orgToken":"$orgToken","requestType":"getProjectRiskReport","projectToken":"$projectToken"}
                curl --header "${header}" --data ${data} ${api} -o $outPdf
              break
            fi
          done
        fi
      fi
    fi
  fi
fi
