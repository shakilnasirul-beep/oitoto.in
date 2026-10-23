<?php
declare(strict_types=1);

namespace OiToto\Core;

class Validator
{
    private array $data;
    private array $rules;
    private array $errors = [];

    public function __construct(array $data, array $rules)
    {
        $this->data = $data;
        $this->rules = $rules;
    }

    public static function make(array $data, array $rules): self
    {
        return new self($data, $rules);
    }

    public function validate(): bool
    {
        $this->errors = [];

        foreach ($this->rules as $field => $fieldRules) {
            $ruleList = is_array($fieldRules) ? $fieldRules : explode('|', $fieldRules);
            $val = $this->data[$field] ?? null;

            foreach ($ruleList as $rule) {
                $params = [];
                if (str_contains($rule, ':')) {
                    [$rule, $paramStr] = explode(':', $rule, 2);
                    $params = explode(',', $paramStr);
                }

                switch ($rule) {
                    case 'required':
                        if ($val === null || $val === '' || (is_array($val) && empty($val))) {
                            $this->errors[$field][] = "The {$field} field is required.";
                        }
                        break;

                    case 'numeric':
                        if ($val !== null && $val !== '' && !is_numeric($val)) {
                            $this->errors[$field][] = "The {$field} must be a number.";
                        }
                        break;

                    case 'phone':
                        if ($val !== null && $val !== '') {
                            $cleaned = preg_replace('/[^0-9]/', '', (string)$val);
                            if (strlen($cleaned) < 10 || strlen($cleaned) > 13) {
                                $this->errors[$field][] = "The {$field} must be a valid 10-digit mobile number.";
                            }
                        }
                        break;

                    case 'email':
                        if ($val !== null && $val !== '' && !filter_var($val, FILTER_VALIDATE_EMAIL)) {
                            $this->errors[$field][] = "The {$field} must be a valid email address.";
                        }
                        break;

                    case 'in':
                        if ($val !== null && $val !== '' && !in_array((string)$val, $params, true)) {
                            $this->errors[$field][] = "The {$field} must be one of: " . implode(', ', $params);
                        }
                        break;

                    case 'min':
                        if ($val !== null && $val !== '') {
                            $min = (float)$params[0];
                            $isNumericRule = in_array('numeric', $ruleList, true) || is_int($val) || is_float($val);
                            if ($isNumericRule && is_numeric($val)) {
                                if ((float)$val < $min) {
                                    $this->errors[$field][] = "The {$field} must be at least {$min}.";
                                }
                            } elseif (is_string($val)) {
                                if (mb_strlen($val) < (int)$min) {
                                    $this->errors[$field][] = "The {$field} must have at least {$min} characters.";
                                }
                            }
                        }
                        break;

                    case 'max':
                        if ($val !== null && $val !== '') {
                            $max = (float)$params[0];
                            $isNumericRule = in_array('numeric', $ruleList, true) || is_int($val) || is_float($val);
                            if ($isNumericRule && is_numeric($val)) {
                                if ((float)$val > $max) {
                                    $this->errors[$field][] = "The {$field} must not exceed {$max}.";
                                }
                            } elseif (is_string($val)) {
                                if (mb_strlen($val) > (int)$max) {
                                    $this->errors[$field][] = "The {$field} must not exceed {$max} characters.";
                                }
                            }
                        }
                        break;
                }
            }
        }

        return empty($this->errors);
    }

    public function getErrors(): array
    {
        return $this->errors;
    }

    public function getFirstError(): string
    {
        foreach ($this->errors as $fieldErrors) {
            return $fieldErrors[0] ?? 'Validation failed.';
        }
        return 'Validation failed.';
    }
}
