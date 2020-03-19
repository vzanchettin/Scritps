#!/bin/bash

# documentacoes
# script escrito por Vinicio Zanchettin, para automatizar quando um spammer encontra uma senha de usuário.
# zanchettin@gmail.com

# Variaveis globais
data=`date`;
dataDia=`date +%d`;
dataMes=`date +%b`;
zmProv="/opt/zimbra/bin/zmprov";
sendEmail="/usr/bin/sendemail";
mailFrom="enviar@teste.com.br";
mailTo="enviar@teste.com.br";
mailUser="enviar@teste.com.br";
mailPass="LCOs908cs08c";
mailServer="smtp.teste.com.br:587";
limiteDeAutenticacoes="200";


for account in `${zmProv} -l gaa`; do

	data=`date`;
	numeroDeAutenticacoes=`cat /var/log/mail.log|grep "${dataMes} ${dataDia}" |grep "sasl_method=LOGIN, sasl_username=${account}"|wc -l`;
	geradorDeSenha=`openssl rand -base64 24`;
	statusAtual=`su - zimbra -c "/opt/zimbra/bin/zmaccts|grep ${account}|awk '{print $2}'"`;

	echo "" >> securityZimbra.log;
	echo "${data} - Iniciado o procedimento na conta ${account}." >> securityZimbra.log;
	echo "${account} tem ${numeroDeAutenticacoes} no ultimo dia" >> securityZimbra.log;


	if [ "${statusAtual}" != "locked" ]; then

		if [ ${numeroDeAutenticacoes} -gt ${limiteDeAutenticacoes} ]; then

			echo "Conta atingiu o limite, será notificado o responsável e tomado ações." >> securityZimbra.log;
			echo "A conta será bloqueada para evitar futuros problemas."  >> securityZimbra.log;
			echo "A senha foi alterada para ${geradorDeSenha}" >> securityZimbra.log;
			
			# envia o e-mail
			${sendEmail} -f ${mailFrom} -t ${mailTo} -xu ${mailUser} -xp ${mailPass} -u "Limite atingido para ${account}" -m "O limite de autenticações para a conta de e-mail ${account} foi atingido, favor averiguar a mesma" -s ${mailServer};
			
			# bloqueia e troca a senha da conta
			${zmProv} ma ${account} zimbraAccountStatus locked;
			${zmProv} sp ${account} ${geradorDeSenha};

		fi
	fi

done
