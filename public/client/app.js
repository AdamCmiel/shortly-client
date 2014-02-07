//Rewrite angular app
var app = angular.module("ShortlyApp", []);

app.run(function($rootScope){
  $rootScope.name = 'adam';
});
app.controller('nameController', function($scope){
  $scope.name = '';
});
