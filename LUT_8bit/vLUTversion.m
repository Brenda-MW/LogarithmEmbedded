%% set up simulation
u = fi(linspace(0.001,20,100));
y = fi_log2lookup_8_bit_byte(u);
y_expected = log2(double(u));

clf
subplot(211)
plot(u,y,u,y_expected)
legend('Output','Expected output','Location','Best')

subplot(212)
plot(u,double(y)-y_expected,'r')
legend('Error')

%% work on code generation
% Generate C code from the function for deployment
codegen fi_log2lookup_8_bit_byte -args {u} -o log2lookup_code

%% Now perform mex version
y_Mex = log2lookup_code(u);

subplot(211)
plot(u,y_Mex,u,y_expected)
legend('Output','Expected output','Location','Best')

subplot(212)
plot(u,double(y_Mex)-y_expected,'r')
legend('Error')

%% Observe generated c code
codegen -config:lib fi_log2lookup_8_bit_byte -args {u} -o log2lookup_execode -launchreport
