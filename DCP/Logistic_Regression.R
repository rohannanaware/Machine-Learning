train.y =
train.X =

sigmoid <- function(z) {
    1/(1+exp(-z))
}

cost = function(theta, X, y,lambda){
    cost_gradient=list()
    h_theta=sigmoid(X%*%theta)
    cost=1/nrow(X)*sum(-y*log(h_theta)-(1-y)*log(1-h_theta))+lambda/(2*nrow(X))*sum(theta^2)
    return(cost)
}

gradient=function(theta, X, y,lambda, alpha=1){
    gradient= 1/nrow(X)*alpha*(sigmoid(t(theta)%*%t(X))-t(y))%*%X+(lambda/(nrow(X)))*c(0,theta[-1])
    return(gradient)                                                                           
}

logistic_regression <- function(theta, X, y, lambda, alpha, p_value = 0.5) {
  optimized         <- optim(par=initial_theta,X=X,y=y,lambda=1,
                             fn=cost,
                             gr=gradient,
                             method="BFGS")
  fitted_result     <- sigmoid(X%*%optimized$par)
  return(fitted_result)
}

initial_theta <- matrix(rep(0,ncol(X)))
fitted_result <- logistic_regression(initial_theta, X = train.X, y = train.y, 0.5, 0.1)
train.y$fitted_result_label=ifelse(fitted_result>=0.5,1,0)

accuracy=sum(train.y$Label==train.y$fitted_result_label)/nrow(train.y)
cat("The accuracy is: ",accuracy)
