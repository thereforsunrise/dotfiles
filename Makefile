FORCE:

lint: FORCE
	@rm -f linter.log
	@time docker-compose run lint | tee linter.log
