export SECRET=2cfe87ce3c0b44138feed9066cc9bd17
export CLIENT_SECRET=NDc0ZDEzNjItZmQxMi00MTBmLTgwZTYtNjBmNjRjMjFlNmYx
DIR="$( cd "$( dirname "$0" )" && pwd )"
alias python=python3
export PYTHONWARNINGS="ignore:Unverified HTTPS request"
python "$DIR/Face.py"