DB_NAME="postgres-test"
	if [ "$(docker ps -a -q -f name=$DB_NAME)" ]; then
          # cleanup
          echo ">>>>>>>> REMOVING EXISTING POSTGRES CONTAINER"
          docker rm $DB_NAME
 fi

